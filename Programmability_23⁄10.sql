/*
================================================================================
  ConeSTeam - Programmability.sql
  Funciones, Procedimientos Almacenados y Triggers
  Proyecto Fase 2 - Bases de Datos - UCV
================================================================================
*/

USE ConeSTeam;
GO

/* ============================================================================
   1. FUNCIONES DEFINIDAS POR EL USUARIO (UDF)
   ============================================================================ */

-- 1.1 fn_calcular_impuesto (@monto) -> Devuelve IVA del 16% (Parametrizable internamente)
CREATE OR ALTER FUNCTION fn_calcular_impuesto (@monto DECIMAL(20,2))
RETURNS DECIMAL(20,2)
AS
BEGIN
    DECLARE @Tasa_IVA DECIMAL(5,2) = 0.16; -- Tasa de impuesto configurable (16%)
    RETURN ISNULL(@monto, 0) * @Tasa_IVA;
END;
GO

-- 1.2 fn_precio_con_descuento (@ID_Producto, @fecha) -> Devuelve precio efectivo en una fecha dada
CREATE OR ALTER FUNCTION fn_precio_con_descuento (
    @ID_Producto smallint,
    @fecha datetime2
)
RETURNS DECIMAL(20,2)
AS
BEGIN
    DECLARE @PrecioEfectivo DECIMAL(20,2);
    DECLARE @PorcentajeDescuento DECIMAL(20,2);
    DECLARE @PrecioBaseEnEvento DECIMAL(20,2);

    IF @fecha IS NULL SET @fecha = GETDATE();

    -- Buscar si existe un descuento vigente para esa fecha
    SELECT TOP 1 
        @PorcentajeDescuento = Porcentaje_Descuento,
        @PrecioBaseEnEvento = Precio_Base_En_Evento
    FROM Historial_Descuento
    WHERE ID_Producto = @ID_Producto
      AND Fecha_Inicio <= CAST(@fecha AS DATE)
      AND (Fecha_Fin IS NULL OR Fecha_Fin >= CAST(@fecha AS DATE))
    ORDER BY Fecha_Inicio DESC;

    IF @PorcentajeDescuento IS NOT NULL AND @PorcentajeDescuento > 0
    BEGIN
        SET @PrecioEfectivo = @PrecioBaseEnEvento * (1.00 - (@PorcentajeDescuento / 100.00));
    END
    ELSE
    BEGIN
        SELECT @PrecioEfectivo = CAST(Precio_Base_Actual AS DECIMAL(20,2))
        FROM Producto_Digital
        WHERE ID_Producto = @ID_Producto;
    END

    RETURN ISNULL(@PrecioEfectivo, 0);
END;
GO

-- 1.3 fn_clasificar_ingreso (@monto) -> Retorna 'AAA', 'Consolidado' o 'Indie'
CREATE OR ALTER FUNCTION fn_clasificar_ingreso (@monto DECIMAL(20,2))
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @Clasificacion NVARCHAR(20);
    SET @monto = ISNULL(@monto, 0);

    IF @monto > 10000.00
        SET @Clasificacion = 'AAA';
    ELSE IF @monto BETWEEN 2000.00 AND 10000.00
        SET @Clasificacion = 'Consolidado';
    ELSE
        SET @Clasificacion = 'Indie';

    RETURN @Clasificacion;
END;
GO

-- 1.4 fn_calcular_reputacion (@ID_Producto) -> Devuelve puntaje (0-100)
CREATE OR ALTER FUNCTION fn_calcular_reputacion (@ID_Producto smallint)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @PromedioCalificacion FLOAT = 0;
    DECLARE @MetacriticScore FLOAT = 0;
    DECLARE @TotalJugadores INT = 0;
    DECLARE @Reputacion DECIMAL(5,2) = 0;

    -- Obtener promedio de reseñas en escala 0-10 (si no hay, tomar 0)
    SELECT @PromedioCalificacion = ISNULL(AVG(CAST(Calificacion_1_10 AS FLOAT)), 0)
    FROM Resena
    WHERE ID_Producto = @ID_Producto;

    -- Obtener Metacritic Score y Total de Jugadores
    SELECT 
        @MetacriticScore = ISNULL(CAST(p.Metacritic_Score AS FLOAT), 0),
        @TotalJugadores = ISNULL(COUNT(b.ID_Usuario), 0)
    FROM Producto_Digital p
    LEFT JOIN Biblioteca b ON b.ID_Producto = p.ID_Producto
    WHERE p.ID_Producto = @ID_Producto
    GROUP BY p.Metacritic_Score;

    -- Fórmula: (PromedioCalificacion * 7) + (MetacriticScore * 0.2) + (TotalJugadores * 0.05)
    SET @Reputacion = (@PromedioCalificacion * 7.0) + (@MetacriticScore * 0.2) + (@TotalJugadores * 0.05);

    -- Tope de 100 puntos
    IF @Reputacion > 100.00
        SET @Reputacion = 100.00;

    RETURN @Reputacion;
END;
GO

-- 1.5 fn_calcular_horas_totales_usuario (@ID_Usuario) -> Devuelve total de horas jugadas
CREATE OR ALTER FUNCTION fn_calcular_horas_totales_usuario (@ID_Usuario smallint)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalHoras DECIMAL(10,2) = 0;

    SELECT @TotalHoras = ISNULL(SUM(CAST(Horas_Jugadas AS DECIMAL(10,2))), 0.0)
    FROM Biblioteca
    WHERE ID_Usuario = @ID_Usuario;

    RETURN @TotalHoras;
END;
GO

-- 1.6 fn_EdadUsuario (@ID_Usuario) -> Devuelve la edad del usuario
CREATE OR ALTER FUNCTION fn_EdadUsuario (@ID_Usuario smallint)
RETURNS int
AS
BEGIN
    DECLARE @Edad int;
    SELECT @Edad = DATEDIFF(year, Fecha_Nacimiento, GETDATE())
    FROM Usuario 
    WHERE ID_Usuario = @ID_Usuario;
    RETURN ISNULL(@Edad, 0);
END;
GO


/* ============================================================================
   2. PROCEDIMIENTOS ALMACENADOS (STORED PROCEDURES)
   ============================================================================ */

-- 2.1 sp_realizar_compra
CREATE OR ALTER PROCEDURE sp_realizar_compra
    @ID_Usuario smallint,
    @ID_Metodo_Pago smallint
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Validar que el carrito no esté vacío
        IF NOT EXISTS (SELECT 1 FROM Carrito WHERE ID_Usuario = @ID_Usuario)
        BEGIN
            RAISERROR('Error: El carrito de compras está vacío.', 16, 1);
        END

        -- 2. Validar que el usuario no posea ya ningún producto del carrito en su Biblioteca
        IF EXISTS (
            SELECT 1 
            FROM Carrito c
            INNER JOIN Biblioteca b ON b.ID_Usuario = c.ID_Usuario AND b.ID_Producto = c.ID_Producto
            WHERE c.ID_Usuario = @ID_Usuario
        )
        BEGIN
            RAISERROR('Error: El usuario ya posee uno o más productos del carrito en su Biblioteca.', 16, 1);
        END

        -- Tabla temporal para calcular precios del checkout
        CREATE TABLE #ItemsCheckout (
            ID_Producto smallint,
            Precio_Historico DECIMAL(20,2),
            Pct_Descuento DECIMAL(20,2),
            Subtotal_Linea DECIMAL(20,2)
        );

        INSERT INTO #ItemsCheckout (ID_Producto, Precio_Historico, Pct_Descuento, Subtotal_Linea)
        SELECT 
            c.ID_Producto,
            dbo.fn_precio_con_descuento(c.ID_Producto, GETDATE()) AS Precio_Historico,
            ISNULL(h.Porcentaje_Descuento, 0) AS Pct_Descuento,
            dbo.fn_precio_con_descuento(c.ID_Producto, GETDATE()) AS Subtotal_Linea
        FROM Carrito c
        LEFT JOIN Historial_Descuento h ON h.ID_Producto = c.ID_Producto
            AND h.Fecha_Inicio <= CAST(GETDATE() AS DATE)
            AND (h.Fecha_Fin IS NULL OR h.Fecha_Fin >= CAST(GETDATE() AS DATE))
        WHERE c.ID_Usuario = @ID_Usuario;

        -- 3. Calcular totales financieros
        DECLARE @SubTotal DECIMAL(20,2);
        DECLARE @MontoDescuento DECIMAL(20,2) = 0;
        DECLARE @MontoImpuesto DECIMAL(20,2);
        DECLARE @TotalPagado DECIMAL(20,2);
        DECLARE @ID_Factura smallint;
        DECLARE @CodigoTransaccion smallint = CAST(ABS(CHECKSUM(NEWID())) % 32767 AS smallint);

        SELECT @SubTotal = ISNULL(SUM(Subtotal_Linea), 0) FROM #ItemsCheckout;
        SET @MontoImpuesto = dbo.fn_calcular_impuesto(@SubTotal);
        SET @TotalPagado = @SubTotal + @MontoImpuesto - @MontoDescuento;

        -- Generar Factura
        INSERT INTO Factura (
            Codigo_Transaccion, Fecha_Hora_Emision, Sub_Total, 
            Monto_Descuento, Monto_Impuesto, Total_Pagado, 
            ID_Usuario, ID_Metodo_Pago
        )
        VALUES (
            @CodigoTransaccion, GETDATE(), @SubTotal, 
            @MontoDescuento, @MontoImpuesto, @TotalPagado, 
            @ID_Usuario, @ID_Metodo_Pago
        );

        SET @ID_Factura = SCOPE_IDENTITY();

        -- Generar Detalle_Factura
        INSERT INTO Detalle_Factura (ID_Factura, ID_Producto, Precio_Venta_Historico, Descuento_Aplicado_Pct)
        SELECT 
            @ID_Factura, 
            ID_Producto, 
            Precio_Historico, 
            Pct_Descuento
        FROM #ItemsCheckout;

        -- Vaciar el carrito
        DELETE FROM Carrito WHERE ID_Usuario = @ID_Usuario;

        DROP TABLE #ItemsCheckout;

        COMMIT TRANSACTION;
        PRINT 'Compra realizada con éxito. ID Factura: ' + CAST(@ID_Factura AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 2.2 sp_dashboard_estudio
CREATE OR ALTER PROCEDURE sp_dashboard_estudio
    @ID_Empresa smallint,
    @Fecha_Inicio datetime2 = NULL,
    @Fecha_Fin datetime2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Fecha_Inicio IS NULL SET @Fecha_Inicio = '2000-01-01';
    IF @Fecha_Fin IS NULL SET @Fecha_Fin = GETDATE();

    -- Tabla 1: KPIs Principales
    SELECT 
        COUNT(DISTINCT df.ID_Producto) AS Total_Productos_Vendidos,
        SUM(df.Precio_Venta_Historico) AS Ingreso_Bruto_Total,
        ISNULL(SUM(r.Monto_Reembolsado), 0) AS Total_Reembolsos,
        (SUM(df.Precio_Venta_Historico) - ISNULL(SUM(r.Monto_Reembolsado), 0)) AS Ingreso_Neto
    FROM Juego_Base jb
    INNER JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
    INNER JOIN Factura f ON f.ID_Factura = df.ID_Factura
    LEFT JOIN Reembolso r ON r.ID_Factura = f.ID_Factura AND r.ID_Producto = df.ID_Producto
    WHERE jb.ID_Estudio_Dev = @ID_Empresa
      AND f.Fecha_Hora_Emision BETWEEN @Fecha_Inicio AND @Fecha_Fin;

    -- Tabla 2: 5 Juegos más vendidos en el período
    SELECT TOP 5
        pd.Titulo,
        COUNT(df.ID_Producto) AS Unidades_Vendidas,
        SUM(df.Precio_Venta_Historico) AS Recaudacion
    FROM Juego_Base jb
    INNER JOIN Producto_Digital pd ON pd.ID_Producto = jb.ID_Producto
    INNER JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
    INNER JOIN Factura f ON f.ID_Factura = df.ID_Factura
    WHERE jb.ID_Estudio_Dev = @ID_Empresa
      AND f.Fecha_Hora_Emision BETWEEN @Fecha_Inicio AND @Fecha_Fin
    GROUP BY pd.ID_Producto, pd.Titulo
    ORDER BY Unidades_Vendidas DESC;

    -- Tabla 3: 5 Mejores compradores del estudio
    SELECT TOP 5
        u.Nickname,
        COUNT(DISTINCT df.ID_Producto) AS Juegos_Comprados,
        SUM(df.Precio_Venta_Historico) AS Gasto_Total
    FROM Juego_Base jb
    INNER JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
    INNER JOIN Factura f ON f.ID_Factura = df.ID_Factura
    INNER JOIN Usuario u ON u.ID_Usuario = f.ID_Usuario
    WHERE jb.ID_Estudio_Dev = @ID_Empresa
      AND f.Fecha_Hora_Emision BETWEEN @Fecha_Inicio AND @Fecha_Fin
    GROUP BY u.ID_Usuario, u.Nickname
    ORDER BY Gasto_Total DESC;
END;
GO

-- 2.3 sp_publicar_producto_con_etiquetas
CREATE OR ALTER PROCEDURE sp_publicar_producto_con_etiquetas
    @ID_Producto smallint,
    @Titulo varchar(70),
    @Descripcion_Corta text,
    @Descripcion_Larga text,
    @Fecha_Lanzamiento date,
    @Tamano_GB DECIMAL(15,2),
    @Clasificacion_Edad varchar(5),
    @Precio_Base_Actual smallint,
    @Tipo_Producto varchar(15),
    @Metacritic_Score DECIMAL(4,1),
    @ID_Estudio_Dev smallint = NULL,
    @ID_Publisher smallint = NULL,
    @Motor_Grafico varchar(25) = NULL,
    @Tiene_Compras_InGame bit = 0,
    @Soporta_Cloud_Saves bit = 0,
    @ID_Juego_Base_DLC smallint = NULL,
    @Tipo_Contenido_DLC varchar(20) = NULL,
    @Subtipo_Jugable_DLC varchar(20) = NULL,
    @EtiquetasCommaSeparated varchar(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insertar Producto Digital
        INSERT INTO Producto_Digital (
            ID_Producto, Titulo, Descripcion_Corta, Descripcion_Larga, 
            Fecha_Lanzamiento, Tamano_GB, Clasificacion_Edad, 
            Precio_Base_Actual, Tipo_Producto, Metacritic_Score
        )
        VALUES (
            @ID_Producto, @Titulo, @Descripcion_Corta, @Descripcion_Larga, 
            @Fecha_Lanzamiento, @Tamano_GB, @Clasificacion_Edad, 
            @Precio_Base_Actual, @Tipo_Producto, @Metacritic_Score
        );

        -- Insertar en Juego_Base o DLC según corresponda
        IF @Tipo_Producto = 'Juego_Base'
        BEGIN
            INSERT INTO Juego_Base (ID_Producto, ID_Estudio_Dev, ID_Publisher, Motor_Grafico, Tiene_Compras_InGame, Soporta_Cloud_Saves)
            VALUES (@ID_Producto, @ID_Estudio_Dev, @ID_Publisher, @Motor_Grafico, @Tiene_Compras_InGame, @Soporta_Cloud_Saves);
        END
        ELSE IF @Tipo_Producto = 'DLC'
        BEGIN
            INSERT INTO DLC (ID_Producto, ID_Juego_Base, Tipo_Contenido, Subtipo_Jugable)
            VALUES (@ID_Producto, @ID_Juego_Base_DLC, @Tipo_Contenido_DLC, @Subtipo_Jugable_DLC);
        END

        -- Procesar lista de etiquetas separadas por coma
        IF @EtiquetasCommaSeparated IS NOT NULL AND LEN(@EtiquetasCommaSeparated) > 0
        BEGIN
            DECLARE @NombreEtiqueta varchar(30);
            DECLARE @ID_Etiqueta smallint;

            DECLARE curEtiquetas CURSOR FOR 
                SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@EtiquetasCommaSeparated, ',');

            OPEN curEtiquetas;
            FETCH NEXT FROM curEtiquetas INTO @NombreEtiqueta;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF LEN(@NombreEtiqueta) > 0
                BEGIN
                    -- Buscar etiqueta o crear si no existe
                    SELECT @ID_Etiqueta = ID_Etiqueta FROM Etiqueta_Comunidad WHERE Nombre_Etiqueta = @NombreEtiqueta;

                    IF @ID_Etiqueta IS NULL
                    BEGIN
                        SELECT @ID_Etiqueta = ISNULL(MAX(ID_Etiqueta), 0) + 1 FROM Etiqueta_Comunidad;
                        INSERT INTO Etiqueta_Comunidad (ID_Etiqueta, Nombre_Etiqueta) VALUES (@ID_Etiqueta, @NombreEtiqueta);
                    END

                    -- Insertar o actualizar relación en Producto_Etiqueta
                    IF NOT EXISTS (SELECT 1 FROM Producto_Etiqueta WHERE ID_Producto = @ID_Producto AND ID_Etiqueta = @ID_Etiqueta)
                    BEGIN
                        INSERT INTO Producto_Etiqueta (ID_Producto, ID_Etiqueta, Cantidad_Votos)
                        VALUES (@ID_Producto, @ID_Etiqueta, 1);
                    END
                END
                FETCH NEXT FROM curEtiquetas INTO @NombreEtiqueta;
            END

            CLOSE curEtiquetas;
            DEALLOCATE curEtiquetas;
        END

        COMMIT TRANSACTION;
        PRINT 'Producto y etiquetas registrados correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 2.4 sp_procesar_reembolso
CREATE OR ALTER PROCEDURE sp_procesar_reembolso
    @ID_Factura smallint,
    @ID_Producto smallint,
    @Motivo text
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @ID_Usuario smallint;
        DECLARE @FechaEmision datetime;
        DECLARE @HorasJugadas int = 0;
        DECLARE @PrecioHistorico DECIMAL(20,2);
        DECLARE @ID_Reembolso smallint;

        -- Obtener datos de la factura
        SELECT 
            @ID_Usuario = f.ID_Usuario,
            @FechaEmision = f.Fecha_Hora_Emision,
            @PrecioHistorico = df.Precio_Venta_Historico
        FROM Factura f
        INNER JOIN Detalle_Factura df ON df.ID_Factura = f.ID_Factura
        WHERE f.ID_Factura = @ID_Factura AND df.ID_Producto = @ID_Producto;

        IF @ID_Usuario IS NULL
        BEGIN
            RAISERROR('Error: La factura o el producto especificado no existen.', 16, 1);
        END

        -- Validar menos de 14 días desde la compra
        IF DATEDIFF(day, @FechaEmision, GETDATE()) > 14
        BEGIN
            RAISERROR('Error: El reembolso supera el límite permitido de 14 días desde la compra.', 16, 1);
        END

        -- Validar menos de 2 horas jugadas
        SELECT @HorasJugadas = ISNULL(Horas_Jugadas, 0)
        FROM Biblioteca
        WHERE ID_Usuario = @ID_Usuario AND ID_Producto = @ID_Producto;

        IF @HorasJugadas >= 2
        BEGIN
            RAISERROR('Error: El usuario no califica para reembolso por acumular 2 o más horas jugadas.', 16, 1);
        END

        -- Obtener nuevo ID de reembolso
        SELECT @ID_Reembolso = ISNULL(MAX(ID_Reembolso), 0) + 1 FROM Reembolso;

        -- Registrar reembolso (Trigger TR_Reembolso_RevocacionAcceso eliminará de Biblioteca)
        INSERT INTO Reembolso (ID_Reembolso, ID_Factura, ID_Producto, Fecha_Reembolso, Monto_Reembolsado, Motivo)
        VALUES (@ID_Reembolso, @ID_Factura, @ID_Producto, CAST(GETDATE() AS DATE), @PrecioHistorico, @Motivo);

        COMMIT TRANSACTION;
        PRINT 'Reembolso procesado con éxito. ID: ' + CAST(@ID_Reembolso AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 2.5 sp_desbloquear_logro
CREATE OR ALTER PROCEDURE sp_desbloquear_logro
    @ID_Usuario smallint,
    @ID_Juego_Base smallint,
    @ID_Logro smallint
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validar que el logro exista para ese Juego Base
        IF NOT EXISTS (SELECT 1 FROM Logro WHERE ID_Juego_Base = @ID_Juego_Base AND ID_Logro = @ID_Logro)
        BEGIN
            RAISERROR('Error: El logro especificado no existe para este juego.', 16, 1);
        END

        -- Validar que el usuario posea el juego en Biblioteca
        IF NOT EXISTS (SELECT 1 FROM Biblioteca WHERE ID_Usuario = @ID_Usuario AND ID_Producto = @ID_Juego_Base)
        BEGIN
            RAISERROR('Error: El usuario no posee el juego base en su biblioteca.', 16, 1);
        END

        -- Verificar que el logro no haya sido desbloqueado previamente
        IF EXISTS (
            SELECT 1 
            FROM Desbloqueo_Logro 
            WHERE ID_Usuario = @ID_Usuario AND ID_Juego_Base = @ID_Juego_Base AND ID_Logro = @ID_Logro
        )
        BEGIN
            RAISERROR('Error: El usuario ya ha desbloqueado este logro previamente.', 16, 1);
        END

        -- Insertar desbloqueo
        INSERT INTO Desbloqueo_Logro (ID_Usuario, ID_Juego_Base, ID_Logro, Fecha_Desbloqueo)
        VALUES (@ID_Usuario, @ID_Juego_Base, @ID_Logro, CAST(GETDATE() AS DATE));

        COMMIT TRANSACTION;
        PRINT 'Logro desbloqueado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 2.6 sp_RegistrarVenta
CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @ID_Usuario smallint,
    @ID_Producto smallint,
    @Precio_Venta DECIMAL(20,2),
    @Descuento_Pct DECIMAL(5,2) = 0,
    @Fecha_Hora datetime2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @Fecha_Hora IS NULL SET @Fecha_Hora = GETDATE();

        INSERT INTO Factura (ID_Usuario, ID_Metodo_Pago, Fecha_Hora_Emision, Total_Pagado)
        VALUES (@ID_Usuario, 7, @Fecha_Hora, @Precio_Venta);

        DECLARE @ID_Factura smallint = SCOPE_IDENTITY();

        INSERT INTO Detalle_Factura (ID_Factura, ID_Producto, Precio_Venta_Historico, Descuento_Aplicado_Pct)
        VALUES (@ID_Factura, @ID_Producto, @Precio_Venta, @Descuento_Pct);

        PRINT 'Venta registrada correctamente para el usuario ' + CAST(@ID_Usuario AS varchar(10));
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- 2.7 sp_CalcularDescuento
CREATE OR ALTER PROCEDURE sp_CalcularDescuento
    @ID_Producto smallint,
    @Fecha datetime2 = NULL,
    @Descuento DECIMAL(5,2) OUTPUT
AS
BEGIN
    SET @Descuento = 0;
    SELECT @Descuento = ISNULL(Porcentaje_Descuento, 0)
    FROM Historial_Descuento h
    WHERE h.ID_Producto = @ID_Producto
      AND h.Fecha_Inicio <= ISNULL(CAST(@Fecha AS DATE), CAST(GETDATE() AS DATE))
      AND (h.Fecha_Fin IS NULL OR h.Fecha_Fin >= ISNULL(CAST(@Fecha AS DATE), CAST(GETDATE() AS DATE)));
END;
GO

-- 2.8 sp_ReporteVentasTop10
CREATE OR ALTER PROCEDURE sp_ReporteVentasTop10
    @Mes smallint = NULL, @Anio smallint = NULL
AS
BEGIN
    SELECT TOP 10 
        p.Titulo, 
        SUM(f.Total_Pagado) AS Total_Vendido,
        COUNT(DISTINCT f.ID_Usuario) AS Usuarios
    FROM Producto_Digital p
    INNER JOIN Detalle_Factura d ON d.ID_Producto = p.ID_Producto
    INNER JOIN Factura f ON f.ID_Factura = d.ID_Factura
    WHERE (@Mes IS NULL OR DATEPART(month, f.Fecha_Hora_Emision) = @Mes)
      AND (@Anio IS NULL OR DATEPART(year, f.Fecha_Hora_Emision) = @Anio)
    GROUP BY p.Titulo
    ORDER BY Total_Vendido DESC;
END;
GO

-- 2.9 sp_ReporteConcurrenciaPromedio
CREATE OR ALTER PROCEDURE sp_ReporteConcurrenciaPromedio
    @ID_Producto smallint = NULL
AS
BEGIN
    SELECT 
        p.Titulo,
        AVG(r.Pico_Maximo_Jugadores) AS Concur_Promedio
    FROM Registro_Concurrencia r
    INNER JOIN Producto_Digital p ON p.ID_Producto = r.ID_Producto
    WHERE (@ID_Producto IS NULL OR r.ID_Producto = @ID_Producto)
    GROUP BY p.Titulo;
END;
GO


/* ============================================================================
   3. TRIGGERS
   ============================================================================ */

-- Trigger 1: Auditoría de Precios
DROP TRIGGER IF EXISTS TR_ProductoDigital_AuditoriaPrecios;
GO

CREATE TRIGGER TR_ProductoDigital_AuditoriaPrecios
ON Producto_Digital
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Precio_Base_Actual)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            INNER JOIN deleted d ON i.ID_Producto = d.ID_Producto
            WHERE d.Precio_Base_Actual > 0
              AND ABS(CAST(i.Precio_Base_Actual AS DECIMAL(10,2)) - CAST(d.Precio_Base_Actual AS DECIMAL(10,2))) 
                  > (CAST(d.Precio_Base_Actual AS DECIMAL(10,2)) * 0.50)
        )
        BEGIN
            RAISERROR('Error: El cambio en Precio_Base_Actual no puede superar el 50%% del precio anterior (variación brusca detectada).', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

-- Trigger 2: Protección de Menores
DROP TRIGGER IF EXISTS TR_DetalleFactura_ProteccionMenores;
GO

CREATE TRIGGER TR_DetalleFactura_ProteccionMenores
ON Detalle_Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Factura f ON f.ID_Factura = i.ID_Factura
        INNER JOIN Usuario u ON u.ID_Usuario = f.ID_Usuario
        INNER JOIN Producto_Digital p ON p.ID_Producto = i.ID_Producto
        WHERE p.Clasificacion_Edad IN ('M', 'AO')
          AND DATEADD(year, 18, u.Fecha_Nacimiento) > CAST(ISNULL(f.Fecha_Hora_Emision, GETDATE()) AS DATE)
    )
    BEGIN
        RAISERROR('Contenido restringido por edad', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger 3: Poblado automático de Biblioteca
DROP TRIGGER IF EXISTS TR_DetalleFactura_PobladoBiblioteca;
GO

CREATE TRIGGER TR_DetalleFactura_PobladoBiblioteca
ON Detalle_Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF @@TRANCOUNT = 0 RETURN;

    INSERT INTO Biblioteca (ID_Usuario, ID_Producto, Horas_Jugadas, Fecha_Ultima_Sesion)
    SELECT DISTINCT 
        f.ID_Usuario, 
        i.ID_Producto, 
        0 AS Horas_Jugadas, 
        NULL AS Fecha_Ultima_Sesion
    FROM inserted i
    INNER JOIN Factura f ON f.ID_Factura = i.ID_Factura
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Biblioteca b 
        WHERE b.ID_Usuario = f.ID_Usuario 
          AND b.ID_Producto = i.ID_Producto
    );
END;
GO

EXEC sp_settriggerorder 
    @triggername = 'TR_DetalleFactura_ProteccionMenores', 
    @order = 'First', 
    @stmttype = 'INSERT';
GO

-- Trigger 4: Reembolso = revocación de acceso
DROP TRIGGER IF EXISTS TR_Reembolso_RevocacionAcceso;
GO

CREATE TRIGGER TR_Reembolso_RevocacionAcceso
ON Reembolso
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE b
    FROM Biblioteca b
    INNER JOIN inserted i ON b.ID_Producto = i.ID_Producto
    INNER JOIN Factura f ON f.ID_Factura = i.ID_Factura 
                        AND b.ID_Usuario = f.ID_Usuario;
END;
GO

-- Trigger 5: Validaciones de Precompra en Carrito
DROP TRIGGER IF EXISTS TR_Carrito_ValidacionesPrecompra;
GO

CREATE TRIGGER TR_Carrito_ValidacionesPrecompra
ON Carrito
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Biblioteca b 
            ON b.ID_Usuario = i.ID_Usuario 
           AND b.ID_Producto = i.ID_Producto
    )
    BEGIN
        RAISERROR('Error: El usuario ya posee este producto en su Biblioteca.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN DLC dlc ON dlc.ID_Producto = i.ID_Producto
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Biblioteca b 
            WHERE b.ID_Usuario = i.ID_Usuario 
              AND b.ID_Producto = dlc.ID_Juego_Base
        )
        AND NOT EXISTS (
            SELECT 1 
            FROM Carrito c 
            WHERE c.ID_Usuario = i.ID_Usuario 
              AND c.ID_Producto = dlc.ID_Juego_Base
              AND c.ID_Producto <> i.ID_Producto
        )
        AND NOT EXISTS (
            SELECT 1 
            FROM inserted ins 
            WHERE ins.ID_Usuario = i.ID_Usuario 
              AND ins.ID_Producto = dlc.ID_Juego_Base
        )
    )
    BEGIN
        RAISERROR('Error: No se puede agregar el DLC al Carrito porque el usuario no posee el Juego Base en su Biblioteca ni se encuentra en el Carrito.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO


/* ============================================================================
   4. VISTAS (VIEWS)
   ============================================================================ */

/* Vista con estadísticas de ventas históricas por producto */
CREATE OR ALTER VIEW vw_VentasProducto
AS
SELECT 
    p.ID_Producto,
    p.Titulo,
    SUM(f.Total_Pagado) AS Total_Vendido,
    COUNT(DISTINCT f.ID_Usuario) AS Usuarios_Que_Compraron,
    MAX(f.Fecha_Hora_Emision) AS Ultima_Compra
FROM Producto_Digital p
INNER JOIN Detalle_Factura d ON d.ID_Producto = p.ID_Producto
INNER JOIN Factura f ON f.ID_Factura = d.ID_Factura
GROUP BY p.ID_Producto, p.Titulo;
GO

/* Vista de concurrencia promedio por producto */
CREATE OR ALTER VIEW vw_ConcurrenciaPromedio
AS
SELECT 
    r.ID_Producto,
    p.Titulo,
    AVG(r.Pico_Maximo_Jugadores) AS Concur_Promedio,
    MAX(r.Pico_Maximo_Jugadores) AS Pico_Historico,
    MIN(r.Pico_Maximo_Jugadores) AS Minimo_Historico
FROM Registro_Concurrencia r
INNER JOIN Producto_Digital p ON p.ID_Producto = r.ID_Producto
GROUP BY r.ID_Producto, p.Titulo;
GO

PRINT 'Programmability.sql compilado y cargado correctamente con todas las funciones, procedimientos y triggers.';
GO
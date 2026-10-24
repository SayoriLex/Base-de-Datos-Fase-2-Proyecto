
--Consulta #1
-- Clasificación de Estudios por Facturación
SELECT 
    ec.Nombre AS Estudio, 
    ec.Pais_Origen, 
    COUNT(DISTINCT df.ID_Producto) AS Juegos_Vendidos, 
    SUM(df.Precio_Venta_Historico) AS Ingreso_Total, 
    dbo.fn_clasificar_ingreso(SUM(df.Precio_Venta_Historico)) AS Clasificacion
FROM Empresa_Corporativa ec
JOIN Juego_Base jb ON jb.ID_Estudio_Dev = ec.ID_Empresa
JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
JOIN Factura f ON f.ID_Factura = df.ID_Factura
WHERE f.Fecha_Hora_Emision >= DATEADD(MONTH, -1, CAST(GETDATE() AS DATE))
GROUP BY ec.ID_Empresa, ec.Nombre, ec.Pais_Origen
ORDER BY Ingreso_Total DESC;

--Consulta #2

WITH ProductoConPuntaje AS (
SELECT c.ID_Categoria,c.Nombre_Categoria,p.Titulo,e.Nombre AS Estudio,
((SELECT COUNT(*) FROM Detalle_Factura WHERE ID_Producto = p.ID_Producto) * 2 +
(SELECT COUNT(*) FROM Resena WHERE ID_Producto = p.ID_Producto) * 1.5 + p.Metacritic_Score) AS Puntaje_Popularidad
FROM Categoria_Oficial c
JOIN Juego_Categoria jc ON c.ID_Categoria = jc.ID_Categoria
JOIN Producto_Digital p ON jc.ID_Producto = p.ID_Producto
JOIN Juego_Base jb ON p.ID_Producto = jb.ID_Producto
JOIN Empresa_Corporativa e ON jb.ID_Estudio_Dev = e.ID_Empresa
)
SELECT Nombre_Categoria,Titulo,Estudio, Puntaje_Popularidad
FROM ProductoConPuntaje p1
WHERE Puntaje_Popularidad = (SELECT MAX(Puntaje_Popularidad)FROM ProductoConPuntaje p2 WHERE p2.ID_Categoria = p1.ID_Categoria)


--Consulta #3

WITH Extraer_Dominio AS(
SELECT SUBSTRING(Correo,CHARINDEX('@',Correo),15) as Dominio
FROM Usuario
)

SELECT Dominio , COUNT(*) as Cantidad_Usuarios
FROM Extraer_Dominio
GROUP BY Dominio
HAVING COUNT(*)>10

--Consulta #4
WITH ComprasOrdenadas AS (
    SELECT 
        f.ID_Usuario,
        f.Fecha_Hora_Emision,
        ROW_NUMBER() OVER (PARTITION BY f.ID_Usuario ORDER BY f.Fecha_Hora_Emision) AS Num_Compra
    FROM Factura f
),
PrimeraSegunda AS (
    SELECT 
        c1.ID_Usuario,
        c1.Fecha_Hora_Emision AS Fecha_Primera_Compra,
        c2.Fecha_Hora_Emision AS Fecha_Segunda_Compra,
        DATEDIFF(DAY, c1.Fecha_Hora_Emision, c2.Fecha_Hora_Emision) AS Dias_Entre_Compras
    FROM ComprasOrdenadas c1
    JOIN ComprasOrdenadas c2 
        ON c1.ID_Usuario = c2.ID_Usuario 
       AND c1.Num_Compra = 1 
       AND c2.Num_Compra = 2
    WHERE DATEDIFF(DAY, c1.Fecha_Hora_Emision, c2.Fecha_Hora_Emision) <= 30
)
SELECT 
    u.Nickname,
    ps.Fecha_Primera_Compra,
    ps.Fecha_Segunda_Compra,
    ps.Dias_Entre_Compras
FROM PrimeraSegunda ps
JOIN Usuario u ON u.ID_Usuario = ps.ID_Usuario
ORDER BY ps.Dias_Entre_Compras;


--Consulta #5

SELECT jb.ID_Estudio_Dev as Estudio, COUNT(jb.ID_Producto) as Cantidad_Juegos, CASE WHEN SUM(pd.Tamano_GB) >= 1024 THEN 
                															   CAST(CAST(ROUND(SUM(pd.Tamano_GB) / 1024.0, 2) AS DECIMAL(10,1)) AS VARCHAR(20)) + ' TB'
            																   ELSE CAST(CAST(ROUND(SUM(pd.Tamano_GB), 2) AS DECIMAL(10,1)) AS VARCHAR(20)) + ' GB' END AS Peso_Total
FROM Producto_Digital pd
JOIN Juego_Base jb ON pd.ID_Producto = jb.ID_Producto 
JOIN Empresa_Corporativa ec ON jb.ID_Estudio_Dev = ec.ID_Empresa 
GROUP BY jb.ID_Estudio_Dev 

--Consulta #6

WITH VentasNetasPorPais AS (
SELECT u.Pais_Residencia AS Pais, SUM(ISNULL(f.Total_Pagado, 0) - ISNULL(r.Monto_Reembolsado, 0)) AS Total_Neto
    FROM Usuario u
    LEFT JOIN Factura f ON u.ID_Usuario = f.ID_Usuario
    LEFT JOIN Reembolso r ON f.ID_Factura = r.ID_Factura
    GROUP BY u.Pais_Residencia
)
SELECT Pais, Total_Neto, FORMAT((Total_Neto * 100.0) / NULLIF(SUM(Total_Neto) OVER(), 0), 'N1') + '%' AS Share
FROM VentasNetasPorPais;

--Consulta #7

SELECT u.Nickname , SUM(f.Total_Pagado ) as Gasto_Total_Historico
FROM Factura f 
JOIN Usuario u ON f.ID_Usuario=u.ID_Usuario
JOIN Biblioteca b ON b.ID_Usuario = u.ID_Usuario 
JOIN Juego_Categoria jc ON jc.ID_Producto = b.ID_Producto 
JOIN Categoria_Oficial co ON jc.ID_Categoria = co.ID_Categoria 
WHERE co.Nombre_Categoria IN ('Estrategia', 'Terror')
GROUP BY u.ID_Usuario , u.Nickname 
HAVING SUM(f.Total_Pagado )>100.00 AND COUNT(DISTINCT co.Nombre_Categoria)=2

--Consulta #8
WITH Agrupar_Generaciones AS(
SELECT u.ID_Usuario, CASE WHEN YEAR(u.Fecha_Nacimiento)<1981 THEN 'Gen X y Anteriores' WHEN YEAR(u.Fecha_Nacimiento)>=1981 AND YEAR(u.Fecha_Nacimiento)<=2000 THEN 'Millennials' WHEN YEAR(u.Fecha_Nacimiento)>2000 THEN 'Gen Z'  END as Generacion
,SUM(f.Total_Pagado) as Usuario_Gastos
From Usuario u
JOIN Factura f ON u.ID_Usuario = f.ID_Usuario 
WHERE u.Estado_Cuenta='Activa'
GROUP BY u.ID_Usuario, u.Fecha_Nacimiento
)

SELECT  Generacion, COUNT(ID_Usuario) as Cantidad_Usuarios_Activos, AVG(Usuario_Gastos) as Gasto_Promedio
FROM Agrupar_Generaciones
GROUP BY Generacion

--Consulta #9

SELECT pd.Titulo, COUNT(ID_Resena) as Total_Resenas, AVG(CAST(r.Calificacion_1_10 AS FLOAT)) as Promedio_Calificacion,CASE WHEN AVG(CAST(r.Calificacion_1_10 AS FLOAT))>=6 AND AVG(CAST(r.Calificacion_1_10 AS FLOAT))<=6.9 THEN 'Divisivo' WHEN AVG(CAST(r.Calificacion_1_10 AS FLOAT))>=4 AND AVG(CAST(r.Calificacion_1_10 AS FLOAT))<=5.9 THEN 'Mixto' WHEN AVG(CAST(r.Calificacion_1_10 AS FLOAT))<= 4 THEN 'Crítico' END as Veredicto
FROM Juego_Base jb 
JOIN Producto_Digital pd ON jb.ID_Producto=pd.ID_Producto
JOIN Resena r ON pd.ID_Producto=r.ID_Producto
GROUP BY pd.ID_Producto, pd.Titulo
HAVING COUNT(ID_Resena)>=20 AND AVG(CAST(r.Calificacion_1_10 AS FLOAT)) < (SELECT AVG(CAST(r.Calificacion_1_10 AS FLOAT)) FROM Juego_Base jb JOIN Producto_Digital pd ON jb.ID_Producto=pd.ID_Producto JOIN Resena r ON pd.ID_Producto=r.ID_Producto)

--Consulta #10
WITH PromedioEstudio AS (
    SELECT 
        jb.ID_Estudio_Dev,
        AVG(CAST(r.Calificacion_1_10 AS FLOAT)) AS Prom_Calif_Estudio
    FROM Juego_Base jb
    JOIN Resena r ON r.ID_Producto = jb.ID_Producto
    GROUP BY jb.ID_Estudio_Dev
),
PromedioReputacion AS (
    SELECT AVG(dbo.fn_calcular_reputacion(jb.ID_Producto)) AS Prom_Rep_Plataforma
    FROM Juego_Base jb
)
SELECT 
    pd.Titulo,
    e.Nombre AS Estudio,
    (SELECT COUNT(*) FROM Biblioteca b WHERE b.ID_Producto = pd.ID_Producto) AS Total_Jugadores,
    AVG(CAST(r.Calificacion_1_10 AS FLOAT)) AS Promedio_Calificacion,
    dbo.fn_calcular_reputacion(pd.ID_Producto) AS Puntaje_Reputacion
FROM Juego_Base jb
JOIN Producto_Digital pd ON pd.ID_Producto = jb.ID_Producto
JOIN Empresa_Corporativa e ON e.ID_Empresa = jb.ID_Estudio_Dev
JOIN Resena r ON r.ID_Producto = pd.ID_Producto
JOIN PromedioEstudio pe ON pe.ID_Estudio_Dev = jb.ID_Estudio_Dev
CROSS JOIN PromedioReputacion pr
WHERE NOT EXISTS (
    SELECT 1 FROM Reembolso re WHERE re.ID_Producto = pd.ID_Producto
)
GROUP BY 
    pd.ID_Producto, 
    pd.Titulo, 
    e.Nombre, 
    pe.Prom_Calif_Estudio, 
    pr.Prom_Rep_Plataforma
HAVING COUNT(r.ID_Resena) >= 20
   AND AVG(CAST(r.Calificacion_1_10 AS FLOAT)) > pe.Prom_Calif_Estudio
   AND dbo.fn_calcular_reputacion(pd.ID_Producto) > pr.Prom_Rep_Plataforma
ORDER BY Puntaje_Reputacion DESC;

--Consulta #11

SELECT u.Nickname, b.Fecha_Ultima_Sesion, COUNT(b.ID_Producto) as Juegos_En_Biblioteca
FROM Usuario u
JOIN Biblioteca b ON u.ID_Usuario=b.ID_Usuario
WHERE u.ID_Usuario NOT IN (SELECT DISTINCT ID_Usuario FROM Resena WHERE ID_Usuario IS NOT NULL)
  AND u.ID_Usuario NOT IN (SELECT DISTINCT ID_Usuario FROM Desbloqueo_Logro)
GROUP BY u.ID_Usuario, u.Nickname, b.Fecha_Ultima_Sesion

--Consulta #12

SELECT TOP 3 ec.Nombre_Etiqueta, SUM(pe.Cantidad_Votos ) as Votos_Totales, COUNT(pe.ID_Producto) as Productos_Asociados
FROM Producto_Digital pd
JOIN Producto_Etiqueta pe ON pe.ID_Producto=pd.ID_Producto
JOIN Etiqueta_Comunidad ec ON ec.ID_Etiqueta=pe.ID_Etiqueta
WHERE YEAR(pd.Fecha_Lanzamiento)=2026 
GROUP BY ec.ID_Etiqueta, ec.Nombre_Etiqueta
ORDER BY ec.Nombre_Etiqueta ASC 

--Consulta #13

SELECT u.Nickname, pd.Titulo as Titulo_Juego, COUNT(ID_Logro) as Total_Logros
FROM Usuario u 
JOIN Desbloqueo_Logro dl ON dl.ID_Usuario=u.ID_Usuario
JOIN Juego_Base jb ON jb.ID_Producto=dl.ID_Juego_Base
JOIN Producto_Digital pd ON jb.ID_Producto=pd.ID_Producto
WHERE NOT EXISTS( SELECT 1 FROM Logro l1 WHERE l1.ID_Juego_Base=jb.ID_Producto AND NOT EXISTS(SELECT 1 FROM Desbloqueo_Logro dl1 WHERE dl1.ID_Usuario = u.ID_Usuario AND dl1.ID_Juego_Base = l1.ID_Juego_Base AND dl1.ID_Logro = l1.ID_Logro) ) 
GROUP BY u.ID_Usuario ,u.Nickname, pd.ID_Producto, pd.Titulo

--Consulta #14
WITH IngresosEstudio AS (
    SELECT 
        e.ID_Empresa,
        e.Nombre AS Estudio,
        e.Pais_Origen,
        SUM(df.Precio_Venta_Historico) AS Ingreso_Bruto,
        ISNULL((
            SELECT SUM(r.Monto_Reembolsado)
            FROM Reembolso r
            JOIN Juego_Base jb2 ON jb2.ID_Producto = r.ID_Producto
            WHERE jb2.ID_Estudio_Dev = e.ID_Empresa
              AND r.Fecha_Reembolso >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
        ), 0) AS Reembolsos
    FROM Empresa_Corporativa e
    JOIN Juego_Base jb ON jb.ID_Estudio_Dev = e.ID_Empresa
    JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
    JOIN Factura f ON f.ID_Factura = df.ID_Factura
    WHERE f.Fecha_Hora_Emision >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
    GROUP BY e.ID_Empresa, e.Nombre, e.Pais_Origen
),
ConComision AS (
    SELECT 
        Estudio,
        Pais_Origen,
        Ingreso_Bruto,
        Reembolsos,
        Ingreso_Bruto - Reembolsos AS Ingreso_Neto,
        dbo.fn_clasificar_ingreso(Ingreso_Bruto) AS Tramo_Comision,
        CASE dbo.fn_clasificar_ingreso(Ingreso_Bruto)
            WHEN 'AAA' THEN 0.30
            WHEN 'Consolidado' THEN 0.25
            ELSE 0.20
        END AS Pct_Comision
    FROM IngresosEstudio
)
SELECT 
    Estudio,
    Pais_Origen,
    Ingreso_Bruto,
    Reembolsos,
    Ingreso_Neto,
    Tramo_Comision,
    Pct_Comision AS Comision,
    Ingreso_Neto * Pct_Comision AS Monto_A_Pagar
FROM ConComision
WHERE (Ingreso_Neto * Pct_Comision) > (
    SELECT AVG(Ingreso_Neto * Pct_Comision) FROM ConComision
)
ORDER BY Monto_A_Pagar DESC;


--Consulta #15
WITH SimsBase AS (
    SELECT pd.ID_Producto
    FROM Producto_Digital pd
    WHERE pd.Titulo = 'Los Sims 4'
),
UsuariosConSims AS (
    SELECT b.ID_Usuario
    FROM Biblioteca b
    JOIN SimsBase s ON s.ID_Producto = b.ID_Producto
),
DLCsPorUsuario AS (
    SELECT 
        f.ID_Usuario,
        COUNT(DISTINCT df.ID_Producto) AS Cantidad_DLCs
    FROM Factura f
    JOIN Detalle_Factura df ON df.ID_Factura = f.ID_Factura
    JOIN DLC d ON d.ID_Producto = df.ID_Producto
    JOIN SimsBase s ON s.ID_Producto = d.ID_Juego_Base
    GROUP BY f.ID_Usuario
    HAVING COUNT(DISTINCT df.ID_Producto) >= 5
),
ModsPorUsuario AS (
    SELECT 
        sm.ID_Usuario,
        COUNT(*) AS Mods_Suscritos
    FROM Suscripcion_Mod sm
    JOIN SimsBase s ON s.ID_Producto = sm.ID_Producto_Base
    GROUP BY sm.ID_Usuario
    HAVING COUNT(*) >= 1
),
GastoFranquicia AS (
    SELECT 
        f.ID_Usuario,
        SUM(df.Precio_Venta_Historico) AS Gasto_Bruto
    FROM Factura f
    JOIN Detalle_Factura df ON df.ID_Factura = f.ID_Factura
    WHERE df.ID_Producto IN (
        SELECT ID_Producto FROM SimsBase
        UNION
        SELECT d.ID_Producto FROM DLC d JOIN SimsBase s ON s.ID_Producto = d.ID_Juego_Base
    )
    GROUP BY f.ID_Usuario
),
ReembolsosFranquicia AS (
    SELECT 
        f.ID_Usuario,
        SUM(r.Monto_Reembolsado) AS Total_Reembolsado
    FROM Reembolso r
    JOIN Factura f ON f.ID_Factura = r.ID_Factura
    WHERE r.ID_Producto IN (
        SELECT ID_Producto FROM SimsBase
        UNION
        SELECT d.ID_Producto FROM DLC d JOIN SimsBase s ON s.ID_Producto = d.ID_Juego_Base
    )
    GROUP BY f.ID_Usuario
)
SELECT 
    u.Nickname,
    d.Cantidad_DLCs,
    m.Mods_Suscritos,
    ISNULL(g.Gasto_Bruto, 0) - ISNULL(re.Total_Reembolsado, 0) AS Dinero_Invertido
FROM UsuariosConSims uc
JOIN Usuario u ON u.ID_Usuario = uc.ID_Usuario
JOIN DLCsPorUsuario d ON d.ID_Usuario = u.ID_Usuario
JOIN ModsPorUsuario m ON m.ID_Usuario = u.ID_Usuario
LEFT JOIN GastoFranquicia g ON g.ID_Usuario = u.ID_Usuario
LEFT JOIN ReembolsosFranquicia re ON re.ID_Usuario = u.ID_Usuario
ORDER BY Dinero_Invertido DESC;

--Consulta #16

SELECT u.Nickname, b.Horas_Jugadas, COUNT(DISTINCT amigo.ID_Usuario) as Amigos_Con_Juego
FROM Usuario u
JOIN Biblioteca b ON u.ID_Usuario = b.ID_Usuario AND b.ID_Producto = (SELECT ID_Producto FROM Producto_Digital pd WHERE pd.Titulo='Overcooked')
JOIN Amistad_Usuario au ON u.ID_Usuario = au.ID_Usuario_Solicitante OR u.ID_Usuario = au.ID_Usuario_Receptor
JOIN Usuario amigo ON (amigo.ID_Usuario = CASE WHEN au.ID_Usuario_Solicitante = u.ID_Usuario THEN au.ID_Usuario_Receptor ELSE au.ID_Usuario_Solicitante END)
JOIN Biblioteca b_amigo ON amigo.ID_Usuario = b_amigo.ID_Usuario AND b_amigo.ID_Producto = (SELECT pd.ID_Producto FROM Producto_Digital pd WHERE pd.Titulo='Overcooked')
WHERE au.Estado_Amistad = 'Aceptada' AND amigo.Estado_Cuenta = 'Activa'
GROUP BY u.ID_Usuario, u.Nickname,b.ID_Producto, b.Horas_Jugadas
HAVING COUNT(DISTINCT amigo.ID_Usuario) >= 2
ORDER BY Amigos_Con_Juego DESC

--Consulta #17

SELECT pd.Titulo, pd.Precio_Base_Actual, COUNT(si.ID_Idioma) as Idiomas_Soportados, COUNT(df.ID_Producto) as Ventas_Full_Price
FROM Producto_Digital pd
JOIN Juego_Base jb ON jb.ID_Producto=pd.ID_Producto
JOIN Detalle_Factura df ON df.ID_Producto=pd.ID_Producto
JOIN Soporte_Idioma si ON si.ID_Producto=pd.ID_Producto
GROUP BY pd.ID_Producto, pd.Titulo
HAVING pd.Precio_Base_Actual>(SELECT AVG(pd.Precio_Base_Actual) as Promedio_general FROM Producto_Digital pd) AND (COUNT( DISTINCT df.ID_Producto)>50 AND df.Descuento_Aplicado_Pct=0) AND COUNT(DISTINCT si.ID_Idioma)>4

    --Consulta #18
WITH Jerarquia AS (
    -- Cima de la jerarquía (empresas que son matriz de alguien)
    SELECT 
        e.ID_Empresa AS ID_Matriz,
        e.ID_Empresa AS ID_Subsidiaria,
        e.Nombre AS Empresa_Matriz_Principal,
        e.Nombre AS Empresa_Subsidiaria,
        0 AS Nivel_Jerarquia
    FROM Empresa_Corporativa e
    WHERE e.ID_Empresa_Matriz IS NULL
      AND EXISTS (
          SELECT 1 FROM Empresa_Corporativa sub 
          WHERE sub.ID_Empresa_Matriz = e.ID_Empresa
      )

    UNION ALL

    SELECT 
        j.ID_Matriz,
        e.ID_Empresa,
        j.Empresa_Matriz_Principal,
        e.Nombre,
        j.Nivel_Jerarquia + 1
    FROM Empresa_Corporativa e
    JOIN Jerarquia j ON e.ID_Empresa_Matriz = j.ID_Subsidiaria
),
ProductosDev AS (
    SELECT 
        jb.ID_Estudio_Dev AS ID_Empresa,
        COUNT(*) AS Productos_Desarrollados
    FROM Juego_Base jb
    GROUP BY jb.ID_Estudio_Dev
),
IngresoNeto AS (
    SELECT 
        jb.ID_Estudio_Dev AS ID_Empresa,
        SUM(df.Precio_Venta_Historico) AS Ventas,
        ISNULL((
            SELECT SUM(r.Monto_Reembolsado)
            FROM Reembolso r
            JOIN Juego_Base jb2 ON jb2.ID_Producto = r.ID_Producto
            WHERE jb2.ID_Estudio_Dev = jb.ID_Estudio_Dev
              AND r.Fecha_Reembolso >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
        ), 0) AS Reembolsos
    FROM Juego_Base jb
    JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
    JOIN Factura f ON f.ID_Factura = df.ID_Factura
    WHERE f.Fecha_Hora_Emision >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
    GROUP BY jb.ID_Estudio_Dev
)
SELECT 
    j.Empresa_Matriz_Principal,
    j.Empresa_Subsidiaria,
    j.Nivel_Jerarquia,
    ISNULL(p.Productos_Desarrollados, 0) AS Productos_Desarrollados,
    ISNULL(i.Ventas, 0) - ISNULL(i.Reembolsos, 0) AS Ingreso_Neto_Mensual
FROM Jerarquia j
LEFT JOIN ProductosDev p ON p.ID_Empresa = j.ID_Subsidiaria
LEFT JOIN IngresoNeto i ON i.ID_Empresa = j.ID_Subsidiaria
WHERE j.Nivel_Jerarquia > 0   -- solo subsidiarias (directas e indirectas)
ORDER BY j.Empresa_Matriz_Principal, j.Nivel_Jerarquia, j.Empresa_Subsidiaria;

--Consulta #19

SELECT u.Nickname, pd.Titulo, r.Calificacion_1_10, COUNT(DISTINCT dl.ID_Logro) as Cantidad_Logros_Desbloqueados,COUNT(DISTINCT l.ID_Logro) as Total_Logros
FROM Resena r
JOIN Usuario u ON r.ID_Usuario = u.ID_Usuario
JOIN Producto_Digital pd ON r.ID_Producto = pd.ID_Producto
JOIN Juego_Base jb ON pd.ID_Producto = jb.ID_Producto
JOIN Logro l ON jb.ID_Producto = l.ID_Juego_Base
LEFT JOIN Desbloqueo_Logro dl ON u.ID_Usuario = dl.ID_Usuario AND l.ID_Juego_Base = dl.ID_Juego_Base AND l.ID_Logro = dl.ID_Logro
WHERE r.Calificacion_1_10<4
GROUP BY u.ID_Usuario ,u.Nickname, pd.ID_Producto, pd.Titulo, r.Calificacion_1_10
HAVING COUNT(DISTINCT l.ID_Logro)>0 AND COUNT(DISTINCT dl.ID_Logro) * 100.00 / COUNT(DISTINCT l.ID_Logro) < 10.00

--Consulta #20
DECLARE @ID_Usuario SMALLINT = 1;   
-- (cambiar según el usuario a probar)

WITH Red AS (
    -- Grado 1
    SELECT 
        CASE WHEN au.ID_Usuario_Solicitante = @ID_Usuario 
             THEN au.ID_Usuario_Receptor 
             ELSE au.ID_Usuario_Solicitante 
        END AS ID_Contacto,
        1 AS Grado
    FROM Amistad_Usuario au
    WHERE (au.ID_Usuario_Solicitante = @ID_Usuario OR au.ID_Usuario_Receptor = @ID_Usuario)
      AND au.Estado_Amistad = 'Aceptada'

    UNION ALL

    -- Grados 2 y 3
    SELECT 
        CASE WHEN au.ID_Usuario_Solicitante = r.ID_Contacto 
             THEN au.ID_Usuario_Receptor 
             ELSE au.ID_Usuario_Solicitante 
        END,
        r.Grado + 1
    FROM Red r
    JOIN Amistad_Usuario au 
        ON (au.ID_Usuario_Solicitante = r.ID_Contacto OR au.ID_Usuario_Receptor = r.ID_Contacto)
       AND au.Estado_Amistad = 'Aceptada'
    WHERE r.Grado < 3
),
Contactos AS (
    SELECT ID_Contacto, MIN(Grado) AS Grado_Separacion
    FROM Red
    WHERE ID_Contacto <> @ID_Usuario
    GROUP BY ID_Contacto
)
SELECT 
    u.Nickname AS Nickname_Contacto,
    c.Grado_Separacion,
    CASE c.Grado_Separacion
        WHEN 1 THEN 'Amigo directo'
        WHEN 2 THEN 'Amigo de un amigo'
        WHEN 3 THEN 'Contacto lejano'
    END AS Cercania,
    (
        SELECT COUNT(*)
        FROM Biblioteca ba
        JOIN Juego_Base jb ON jb.ID_Producto = ba.ID_Producto
        WHERE ba.ID_Usuario = c.ID_Contacto
          AND NOT EXISTS (
              SELECT 1 FROM Biblioteca byo
              WHERE byo.ID_Usuario = @ID_Usuario
                AND byo.ID_Producto = ba.ID_Producto
          )
    ) AS Juegos_Recomendables
FROM Contactos c
JOIN Usuario u ON u.ID_Usuario = c.ID_Contacto
WHERE (
    SELECT COUNT(*)
    FROM Biblioteca ba
    JOIN Juego_Base jb ON jb.ID_Producto = ba.ID_Producto
    WHERE ba.ID_Usuario = c.ID_Contacto
      AND NOT EXISTS (
          SELECT 1 FROM Biblioteca byo
          WHERE byo.ID_Usuario = @ID_Usuario
            AND byo.ID_Producto = ba.ID_Producto
      )
) >= 1
ORDER BY c.Grado_Separacion ASC, Juegos_Recomendables DESC;

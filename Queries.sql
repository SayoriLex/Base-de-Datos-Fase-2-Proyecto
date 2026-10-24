
--Consulta #1

SELECT ec.Nombre AS Estudio, ec.Pais_Origen, COUNT(df.ID_Producto) AS Juegos_Vendidos, SUM(df.Precio_Venta_Historico) AS Ingreso_Total, dbo.fn_clasificar_ingreso(SUM(df.Precio_Venta_Historico)) AS Clasificacion
FROM Empresa_Corporativa ec
JOIN Juego_Base jb ON jb.ID_Estudio_Dev = ec.ID_Empresa
JOIN Detalle_Factura df ON df.ID_Producto = jb.ID_Producto
JOIN Factura f ON f.ID_Factura = df.ID_Factura
WHERE f.Fecha_Hora_Emision >= DATEADD(month, -1, GETDATE())
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

--Consulta #4 --Tengo que pensarlo


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



--Consulta #15 --Tengo que revisarlo

WITH Sims AS (
    SELECT pd.ID_Producto
    FROM Producto_Digital pd
    JOIN Juego_Base jb ON jb.ID_Producto = pd.ID_Producto 
    WHERE pd.Titulo = 'Los Sims 4'
)

SELECT u.Nickname, ( SELECT COUNT(d.ID_Juego_Base) FROM DLC d WHERE d.ID_Juego_Base = s.ID_Producto) AS Cantidad_DLCs,
(SELECT COUNT(sm.ID_Mod) FROM Suscripcion_Mod sm WHERE sm.ID_Producto_Base = s.ID_Producto AND sm.ID_Usuario = u.ID_Usuario) AS Mods_Suscritos,
(SELECT ISNULL(SUM(f.Sub_Total), 0) FROM Factura f JOIN Detalle_Factura df ON f.ID_Factura = df.ID_Factura WHERE f.ID_Usuario = u.ID_Usuario) AS Dinero_Invertido
FROM Usuario u
JOIN Biblioteca b ON u.ID_Usuario = b.ID_Usuario
JOIN Sims s ON s.ID_Producto = b.ID_Producto;


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

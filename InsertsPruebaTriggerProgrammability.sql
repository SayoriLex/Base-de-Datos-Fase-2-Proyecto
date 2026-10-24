/*
================================================================================
  Inserts_Minimos_Prueba.sql
  Seed mínimo para que Queries + Programmability no devuelvan tablas vacías
  Ejecutar DESPUÉS de: DDL.sql → Lookups.sql → Programmability.sql
================================================================================
*/

USE ConeSTeam;
GO

/* ------------------------------------------------------------------ */
/* 1. EMPRESAS (con jerarquía matriz → subsidiaria)                   */
/* ------------------------------------------------------------------ */
INSERT INTO Empresa_Corporativa (ID_Empresa, Nombre, Pais_Origen, Fecha_Fundacion, ID_Empresa_Matriz) VALUES
(1,  'Electronic Arts',   'USA',        '1982-05-28', NULL),
(2,  'Maxis',             'USA',        '1987-06-01', 1),      -- subsidiaria de EA
(3,  'Ghost Games',       'Suecia',     '2011-01-01', 1),      -- subsidiaria de EA
(4,  'Team17',            'UK',         '1990-12-01', NULL),
(5,  'Ghost Town Games',  'UK',         '2014-01-01', 4),      -- subsidiaria de Team17
(6,  'CD Projekt',        'Polonia',    '1994-05-01', NULL),
(7,  'FromSoftware',      'Japon',      '1986-11-01', NULL),
(8,  'Valve',             'USA',        '1996-08-24', NULL);

/* ------------------------------------------------------------------ */
/* 2. PRODUCTOS DIGITALES                                             */
/* ------------------------------------------------------------------ */
INSERT INTO Producto_Digital (ID_Producto, Titulo, Descripcion_Corta, Descripcion_Larga, Fecha_Lanzamiento, Tamano_GB, Clasificacion_Edad, Precio_Base_Actual, Tipo_Producto, Metacritic_Score) VALUES
-- Juegos Base
(1,  'Los Sims 4',          'Simulador de vida',           'Crea y controla sims',              '2014-09-02', 18.50, 'T',  40, 'Juego_Base', 70.0),
(2,  'Overcooked',          'Cocina cooperativa',          'Cocina en caos con amigos',         '2016-08-03',  2.10, 'E',  17, 'Juego_Base', 81.0),
(3,  'Elden Ring',          'Action RPG souls',            'Mundo abierto challenging',         '2022-02-25', 60.00, 'M',  60, 'Juego_Base', 96.0),
(4,  'Cyberpunk 2077',      'RPG futurista',               'Night City open world',             '2020-12-10', 70.00, 'M',  50, 'Juego_Base', 86.0),
(5,  'Counter-Strike 2',    'Shooter táctico',             'FPS competitivo',                   '2023-09-27', 30.00, 'M',   0, 'Juego_Base', 82.0),
(6,  'Need for Speed',      'Carreras arcade',             'Callejeras y personalización',      '2015-11-03', 25.00, 'T',  30, 'Juego_Base', 68.0),
(7,  'The Witcher 3',       'RPG de fantasía',             'Geralt caza monstruos',             '2015-05-19', 50.00, 'M',  40, 'Juego_Base', 93.0),
(8,  'Portal 2',            'Puzzle first person',         'Cámaras de prueba con portales',    '2011-04-19',  8.00, 'E',  10, 'Juego_Base', 95.0),
-- DLCs de Los Sims 4
(9,  'Sims 4 Get Together', 'DLC expansión',               'Fiestas y clubes',                  '2015-12-08',  3.50, 'T',  20, 'DLC',        75.0),
(10, 'Sims 4 Cats Dogs',    'DLC mascotas',                'Gatos y perros',                    '2017-11-10',  4.00, 'E',  20, 'DLC',        78.0),
(11, 'Sims 4 Seasons',      'DLC estaciones',              'Clima y festividades',              '2018-06-22',  2.80, 'E',  20, 'DLC',        80.0),
(12, 'Sims 4 Island Living','DLC isla',                    'Vida tropical',                     '2019-06-21',  3.20, 'T',  20, 'DLC',        77.0),
(13, 'Sims 4 Snowy Escape', 'DLC montaña',                 'Japón invernal',                    '2020-11-13',  3.00, 'T',  20, 'DLC',        76.0),
(14, 'Sims 4 Cottage Living','DLC granja',                 'Vida rural',                        '2021-07-22',  2.50, 'E',   0, 'DLC',        79.0),  -- gratuito
-- DLC Overcooked
(15, 'Overcooked Extra',    'DLC niveles',                 'Más cocinas caóticas',              '2017-05-01',  0.80, 'E',   5, 'DLC',        70.0);

/* ------------------------------------------------------------------ */
/* 3. JUEGO_BASE + DLC                                                */
/* ------------------------------------------------------------------ */
INSERT INTO Juego_Base (ID_Producto, ID_Estudio_Dev, ID_Publisher, Motor_Grafico, Tiene_Compras_InGame, Soporta_Cloud_Saves) VALUES
(1, 2, 1, 'EA Proprietary', 1, 1),   -- Sims 4 → Maxis / EA
(2, 5, 4, 'Unity',          0, 1),   -- Overcooked → Ghost Town / Team17
(3, 7, 7, 'Proprietary',    0, 1),   -- Elden Ring → FromSoftware
(4, 6, 6, 'REDengine',      1, 1),   -- Cyberpunk → CD Projekt
(5, 8, 8, 'Source 2',       0, 1),   -- CS2 → Valve
(6, 3, 1, 'Frostbite',      0, 1),   -- NFS → Ghost Games / EA
(7, 6, 6, 'REDengine',      0, 1),   -- Witcher 3 → CD Projekt
(8, 8, 8, 'Source',         0, 1);   -- Portal 2 → Valve

INSERT INTO DLC (ID_Producto, ID_Juego_Base, Tipo_Contenido, Subtipo_Jugable) VALUES
(9,  1, 'Jugable', 'Modo_Juego'),
(10, 1, 'Jugable', 'Modo_Juego'),
(11, 1, 'Jugable', 'Modo_Juego'),
(12, 1, 'Jugable', 'Modo_Juego'),
(13, 1, 'Jugable', 'Modo_Juego'),
(14, 1, 'Jugable', 'Modo_Juego'),
(15, 2, 'Jugable', 'Mapa');

/* ------------------------------------------------------------------ */
/* 4. CATEGORÍAS (usar las del Lookups + extras)                      */
/* ------------------------------------------------------------------ */
-- Las 1-16 ya vienen del Lookups. Agregamos 4 más como pide el enunciado.
INSERT INTO Categoria_Oficial (ID_Categoria, Nombre_Categoria, Descripcion_Categoria) VALUES
(17, 'Survival',     'Supervivencia y crafting'),
(18, 'Roguelike',    'Runs procedurales'),
(19, 'Metroidvania', 'Exploración no lineal'),
(20, 'Battle Royale','Último en pie');

INSERT INTO Juego_Categoria (ID_Producto, ID_Categoria) VALUES
(1, 8), (1, 11),           -- Sims: Simulación, Un Jugador
(2, 16), (2, 12),          -- Overcooked: Cooperativo, Multijugador
(3, 3), (3, 1), (3, 10),   -- Elden: RPG, Acción, Mundo Abierto
(4, 3), (4, 10),           -- Cyberpunk: RPG, Mundo Abierto
(5, 15), (5, 12),          -- CS2: Shooter, Multijugador
(6, 7),                    -- NFS: Carreras
(7, 3), (7, 10),           -- Witcher: RPG, Mundo Abierto
(8, 13),                   -- Portal: Puzzle
(3, 5),                    -- Elden también Terror (para query #7)
(4, 4);                    -- Cyberpunk también Estrategia (para query #7)

/* ------------------------------------------------------------------ */
/* 5. IDIOMAS / SOPORTE                                               */
/* ------------------------------------------------------------------ */
INSERT INTO Soporte_Idioma (ID_Producto, ID_Idioma, Soporta_Interfaz, Soporta_Audio, Soporta_Subtitulos) VALUES
(1,1,1,0,1),(1,2,1,1,1),(1,3,1,0,1),(1,4,1,0,1),  -- Sims ≥4 idiomas
(2,1,1,0,1),(2,2,1,1,1),
(3,1,1,0,1),(3,2,1,1,1),(3,7,1,1,1),(3,9,1,0,1),
(4,1,1,0,1),(4,2,1,1,1),(4,3,1,0,1),(4,5,1,0,1),
(5,2,1,1,1),(5,1,1,0,1),
(6,1,1,0,1),(6,2,1,1,1),
(7,1,1,0,1),(7,2,1,1,1),(7,3,1,0,1),(7,10,1,0,1),
(8,1,1,0,1),(8,2,1,1,1);

/* ------------------------------------------------------------------ */
/* 6. PERFILES DE REQUISITOS                                          */
/* ------------------------------------------------------------------ */
INSERT INTO Perfil_Requisito (ID_Producto, Tipo_Perfil, Sistema_Operativo, Procesador, Memoria_RAM, Tarjeta_Grafica) VALUES
(1,'Minimo','Windows 10','Intel i3','4','GTX 650'),
(1,'Recomendado','Windows 10','Intel i5','8','GTX 960'),
(2,'Minimo','Windows 7','Dual Core','2','Intel HD'),
(2,'Recomendado','Windows 10','i5','4','GTX 750'),
(3,'Minimo','Windows 10','i5-8400','12','GTX 1060'),
(3,'Recomendado','Windows 10','i7-10700K','16','RTX 3070'),
(4,'Minimo','Windows 10','i5-3570K','8','GTX 780'),
(4,'Recomendado','Windows 10','i7-4790','12','RTX 2060'),
(5,'Minimo','Windows 10','i5','8','GTX 1050'),
(5,'Recomendado','Windows 10','i7','16','RTX 3060'),
(6,'Minimo','Windows 10','i3','4','GTX 750'),
(6,'Recomendado','Windows 10','i5','8','GTX 970'),
(7,'Minimo','Windows 7','i5-2500K','6','GTX 660'),
(7,'Recomendado','Windows 10','i7','8','GTX 970'),
(8,'Minimo','Windows 7','Dual Core','2','Intel HD'),
(8,'Recomendado','Windows 10','i5','4','GTX 650');

/* ------------------------------------------------------------------ */
/* 7. LOGROS (para división y críticos inexpertos)                    */
/* ------------------------------------------------------------------ */
INSERT INTO Logro (ID_Juego_Base, ID_Logro, Nombre_Logro, Descripcion_Logro, Es_Secreto) VALUES
(1,1,'First Sim','Crea tu primer sim',0),
(1,2,'House Owner','Compra una casa',0),
(1,3,'Party Time','Organiza una fiesta',0),
(1,4,'Max Skill','Subir skill al máximo',1),
(1,5,'Millionaire','Acumular 100k simoleones',0),
(2,1,'First Service','Completa un servicio',0),
(2,2,'Perfect Order','Orden perfecta',0),
(2,3,'Teamwork','Gana en coop',0),
(3,1,'Shardbearer','Derrota un shardbearer',0),
(3,2,'Elden Lord','Final del juego',0),
(3,3,'Legendary','Arma legendaria',1),
(8,1,'Portal Spawner','Coloca el primer portal',0),
(8,2,'Companion Cube','No mates al cube',0),
(8,3,'Wake Up','Termina el juego',0);

/* ------------------------------------------------------------------ */
/* 8. ETIQUETAS                                                       */
/* ------------------------------------------------------------------ */
INSERT INTO Etiqueta_Comunidad (ID_Etiqueta, Nombre_Etiqueta) VALUES
(1,'Singleplayer'),(2,'Multiplayer'),(3,'Co-op'),(4,'Open World'),
(5,'RPG'),(6,'Souls-like'),(7,'Simulation'),(8,'Puzzle'),
(9,'Competitive'),(10,'Story Rich');

INSERT INTO Producto_Etiqueta (ID_Producto, ID_Etiqueta, Cantidad_Votos) VALUES
(1,1,120),(1,7,200),
(2,2,150),(2,3,180),
(3,4,300),(3,5,280),(3,6,350),
(4,4,220),(4,5,190),
(5,2,400),(5,9,380),
(7,4,250),(7,5,270),(7,10,200),
(8,1,90),(8,8,160);

/* ------------------------------------------------------------------ */
/* 9. USUARIOS (dominios para query #3 + activos/suspendidos)         */
/* ------------------------------------------------------------------ */
INSERT INTO Usuario (ID_Usuario, Nickname, Correo, Contrasena_Hash, Fecha_Nacimiento, Fecha_Registro, Pais_Residencia, Estado_Cuenta) VALUES
(1,  'gamer_vzla',    'gamer1@gmail.com',     'hash1',  '1995-03-12', '2024-06-01', 'Venezuela', 'Activa'),
(2,  'sims_lover',    'sims@gmail.com',       'hash2',  '1998-07-22', '2024-07-15', 'Colombia',  'Activa'),
(3,  'chef_pro',      'chef@gmail.com',       'hash3',  '1992-11-05', '2024-08-20', 'Mexico',    'Activa'),
(4,  'souls_fan',     'souls@gmail.com',      'hash4',  '1988-01-30', '2024-09-01', 'España',    'Activa'),
(5,  'night_city',    'cyber@gmail.com',      'hash5',  '2001-05-18', '2025-01-10', 'Argentina', 'Activa'),
(6,  'valve_kid',     'valve@gmail.com',      'hash6',  '2003-09-09', '2025-02-14', 'Chile',     'Activa'),
(7,  'racing_queen',  'race@gmail.com',       'hash7',  '1990-12-25', '2025-03-01', 'Peru',      'Activa'),
(8,  'witcher_fan',   'witch@gmail.com',      'hash8',  '1985-04-17', '2025-04-05', 'USA',       'Activa'),
(9,  'portal_master', 'portal@gmail.com',     'hash9',  '1997-08-08', '2025-05-12', 'Canada',    'Activa'),
(10, 'lurker01',      'lurk1@gmail.com',      'hash10', '1999-02-14', '2025-06-01', 'Brasil',    'Activa'),
(11, 'lurker02',      'lurk2@yahoo.com',      'hash11', '2000-06-20', '2025-06-15', 'Venezuela', 'Activa'),
(12, 'banned_user',   'ban@hotmail.com',      'hash12', '1994-10-10', '2024-05-01', 'Mexico',    'Baneada'),
(13, 'suspendido',    'sus@outlook.com',      'hash13', '1996-03-03', '2024-11-11', 'España',    'Suspendida'),
(14, 'gmail_user1',   'u1@gmail.com',         'hash14', '1993-01-01', '2025-01-01', 'USA',       'Activa'),
(15, 'gmail_user2',   'u2@gmail.com',         'hash15', '1994-02-02', '2025-01-02', 'USA',       'Activa'),
(16, 'gmail_user3',   'u3@gmail.com',         'hash16', '1995-03-03', '2025-01-03', 'USA',       'Activa'),
(17, 'gmail_user4',   'u4@gmail.com',         'hash17', '1996-04-04', '2025-01-04', 'USA',       'Activa'),
(18, 'gmail_user5',   'u5@gmail.com',         'hash18', '1997-05-05', '2025-01-05', 'USA',       'Activa'),
(19, 'gmail_user6',   'u6@gmail.com',         'hash19', '1998-06-06', '2025-01-06', 'USA',       'Activa'),
(20, 'gmail_user7',   'u7@gmail.com',         'hash20', '1999-07-07', '2025-01-07', 'USA',       'Activa'),
(21, 'gmail_user8',   'u8@gmail.com',         'hash21', '2000-08-08', '2025-01-08', 'USA',       'Activa'),
(22, 'gmail_user9',   'u9@gmail.com',         'hash22', '2001-09-09', '2025-01-09', 'USA',       'Activa'),
(23, 'gmail_user10',  'u10@gmail.com',        'hash23', '2002-10-10','2025-01-10', 'USA',       'Activa'),
(24, 'yahoo_user1',   'y1@yahoo.com',         'hash24', '1991-11-11','2025-02-01', 'Canada',    'Activa'),
(25, 'yahoo_user2',   'y2@yahoo.com',         'hash25', '1992-12-12','2025-02-02', 'Canada',    'Activa');

/* ------------------------------------------------------------------ */
/* 10. AMISTADES (para #16 y #20)                                     */
/* ------------------------------------------------------------------ */
INSERT INTO Amistad_Usuario (ID_Usuario_Solicitante, ID_Usuario_Receptor, Fecha_Amistad, Estado_Amistad) VALUES
(1,2,'2025-01-15','Aceptada'),
(1,3,'2025-01-16','Aceptada'),
(1,4,'2025-01-17','Aceptada'),
(2,3,'2025-02-01','Aceptada'),
(2,5,'2025-02-02','Aceptada'),
(3,4,'2025-02-10','Aceptada'),
(3,6,'2025-02-11','Aceptada'),
(4,5,'2025-03-01','Aceptada'),
(5,6,'2025-03-05','Aceptada'),
(6,7,'2025-03-10','Aceptada'),
(7,8,'2025-04-01','Aceptada'),
(8,9,'2025-04-05','Aceptada'),
(1,5,'2025-04-10','Aceptada'),
(2,4,'2025-04-15','Aceptada'),
(3,5,'2025-05-01','Aceptada');

/* ------------------------------------------------------------------ */
/* 11. FACTURAS + DETALLE (MES ACTUAL + histórico)                    */
/*     Fecha actual ≈ oct 2026 → metemos facturas de sep/oct 2026     */
/* ------------------------------------------------------------------ */
INSERT INTO Factura (ID_Factura, Codigo_Transaccion, Fecha_Hora_Emision, Sub_Total, Monto_Descuento, Monto_Impuesto, Total_Pagado, ID_Usuario, ID_Metodo_Pago) VALUES
-- Mes actual / último mes (crítico para #1 y #14)
(1, 1001, '2026-10-05 10:00:00', 40.00, 0, 6.40, 46.40, 1, 1),
(2, 1002, '2026-10-06 11:00:00', 17.00, 0, 2.72, 19.72, 2, 1),
(3, 1003, '2026-10-07 12:00:00', 60.00, 0, 9.60, 69.60, 3, 3),
(4, 1004, '2026-10-08 13:00:00', 50.00, 0, 8.00, 58.00, 4, 1),
(5, 1005, '2026-10-09 14:00:00', 30.00, 0, 4.80, 34.80, 5, 2),
(6, 1006, '2026-10-10 15:00:00', 40.00, 0, 6.40, 46.40, 6, 1),
(7, 1007, '2026-09-20 10:00:00', 20.00, 0, 3.20, 23.20, 1, 1),  -- mes pasado
(8, 1008, '2026-09-22 11:00:00', 20.00, 0, 3.20, 23.20, 2, 1),
(9, 1009, '2026-09-25 12:00:00', 20.00, 0, 3.20, 23.20, 2, 1),
(10,1010, '2026-10-11 16:00:00', 20.00, 0, 3.20, 23.20, 2, 1),
(11,1011, '2026-10-12 17:00:00', 20.00, 0, 3.20, 23.20, 2, 1),
(12,1012, '2026-10-13 18:00:00', 20.00, 0, 3.20, 23.20, 2, 1),
(13,1013, '2026-10-01 09:00:00', 17.00, 0, 2.72, 19.72, 3, 1),
(14,1014, '2026-10-02 09:30:00',  5.00, 0, 0.80,  5.80, 3, 1),
(15,1015, '2026-08-15 10:00:00', 40.00, 0, 6.40, 46.40, 1, 7),  -- histórico para recompra
(16,1016, '2026-08-20 11:00:00', 17.00, 0, 2.72, 19.72, 1, 7);  -- 2da compra <30 días

INSERT INTO Detalle_Factura (ID_Factura, ID_Producto, Precio_Venta_Historico, Descuento_Aplicado_Pct) VALUES
(1, 1, 40.00, 0),
(2, 2, 17.00, 0),
(3, 3, 60.00, 0),
(4, 4, 50.00, 0),
(5, 6, 30.00, 0),
(6, 7, 40.00, 0),
(7, 9, 20.00, 0),   -- DLC Sims
(8,10, 20.00, 0),
(9,11, 20.00, 0),
(10,12,20.00, 0),
(11,13,20.00, 0),
(12,14, 0.00, 0),   -- gratuito
(13, 2, 17.00, 0),
(14,15,  5.00, 0),
(15, 1, 40.00, 0),
(16, 2, 17.00, 0);

/* ------------------------------------------------------------------ */
/* 12. BIBLIOTECA (se llena también por trigger, pero sembramos)      */
/* ------------------------------------------------------------------ */
INSERT INTO Biblioteca (ID_Usuario, ID_Producto, Horas_Jugadas, Fecha_Ultima_Sesion) VALUES
(1,1,25,'2026-10-10'),
(1,2, 8,'2026-10-05'),
(2,1,40,'2026-10-12'),
(2,9,10,'2026-10-11'),
(2,10,5,'2026-10-11'),
(2,11,3,'2026-10-11'),
(2,12,2,'2026-10-11'),
(2,13,1,'2026-10-11'),
(2,14,1,'2026-10-11'),
(3,2,15,'2026-10-08'),
(3,15,4,'2026-10-08'),
(4,3,60,'2026-10-09'),
(5,4,30,'2026-10-07'),
(6,7,45,'2026-10-06'),
(7,6,12,'2026-10-04'),
(8,7,50,'2026-10-03'),
(9,8,20,'2026-10-02'),
(10,1, 2, NULL),          -- lurker
(11,2, 1, NULL);          -- lurker

/* ------------------------------------------------------------------ */
/* 13. RESEÑAS (≥20 para algunos juegos)                              */
/* ------------------------------------------------------------------ */
INSERT INTO Resena (ID_Resena, ID_Usuario, ID_Producto, Texto_Resena, Calificacion_1_10, Fecha_Publicacion, Es_Critica_Especializada) VALUES
(1,1,1,'Muy adictivo',8,'2026-09-01',0),
(2,2,1,'El mejor simulador',9,'2026-09-02',0),
(3,3,1,'Bueno pero caro',6,'2026-09-03',0),
(4,4,1,'Clásico',7,'2026-09-04',0),
(5,5,1,'Recomendado',8,'2026-09-05',0),
(6,1,3,'Difícil pero justo',9,'2026-09-10',0),
(7,2,3,'Obra maestra',10,'2026-09-11',1),
(8,3,3,'Demasiado hardcore',5,'2026-09-12',0),
(9,4,3,'Excelente',9,'2026-09-13',0),
(10,5,3,'Top',10,'2026-09-14',0),
(11,6,3,'Me encantó',9,'2026-09-15',0),
(12,7,3,'Largo y bueno',8,'2026-09-16',0),
(13,8,3,'Jefes épicos',9,'2026-09-17',0),
(14,9,3,'Mundo increíble',10,'2026-09-18',0),
(15,1,3,'Repetiría',8,'2026-09-19',0),
(16,2,3,'10/10',10,'2026-09-20',0),
(17,3,3,'Desafiante',7,'2026-09-21',0),
(18,4,3,'Arte',9,'2026-09-22',0),
(19,5,3,'Historia top',9,'2026-09-23',0),
(20,6,3,'Combate genial',8,'2026-09-24',0),
(21,7,3,'Rejugable',9,'2026-09-25',0),
(22,8,3,'Must play',10,'2026-09-26',0),
(23,9,3,'Perfecto',9,'2026-09-27',0),
(24,1,3,'Otra vez',8,'2026-09-28',0),
(25,2,3,'Legendario',10,'2026-09-29',0),
(26,4,4,'Buggy al inicio',3,'2026-08-01',0),  -- crítica baja + poco progreso
(27,5,4,'Mejoró mucho',7,'2026-08-10',0),
(28,6,2,'Divertido en coop',8,'2026-09-01',0),
(29,7,2,'Caótico',7,'2026-09-02',0),
(30,8,7,'Mejor RPG',10,'2026-09-05',1);

/* ------------------------------------------------------------------ */
/* 14. DESBLOQUEO LOGROS (usuario 9 completa Portal 2 → query #13)    */
/* ------------------------------------------------------------------ */
INSERT INTO Desbloqueo_Logro (ID_Usuario, ID_Juego_Base, ID_Logro, Fecha_Desbloqueo) VALUES
(9,8,1,'2026-09-01'),
(9,8,2,'2026-09-05'),
(9,8,3,'2026-09-10'),
(4,3,1,'2026-09-15'),
(4,3,2,'2026-10-01'),
(1,1,1,'2026-09-20'),
(2,1,1,'2026-09-21'),
(2,1,2,'2026-09-22');

/* ------------------------------------------------------------------ */
/* 15. MODS + SUSCRIPCIONES (para #15)                                */
/* ------------------------------------------------------------------ */
INSERT INTO Mod (ID_Producto_Base, ID_Mod, Nombre_Mod, Descripcion_Mod, Tamano_MB) VALUES
(1,1,'Custom Cas','Más ropa',50),
(1,2,'Better Build','Construcción avanzada',30),
(2,1,'Extra Kitchens','Nuevas cocinas',20);

INSERT INTO Suscripcion_Mod (ID_Usuario, ID_Producto_Base, ID_Mod, Fecha_Suscripcion) VALUES
(2,1,1,'2026-09-01'),
(2,1,2,'2026-09-02'),
(3,2,1,'2026-09-10');

/* ------------------------------------------------------------------ */
/* 16. REEMBOLSOS (mínimo para #6 y #14)                              */
/* ------------------------------------------------------------------ */
INSERT INTO Reembolso (ID_Reembolso, ID_Factura, ID_Producto, Fecha_Reembolso, Monto_Reembolsado, Motivo) VALUES
(1,5,6,'2026-10-12',30.00,'No me gustó'),
(2,4,4,'2026-10-13',50.00,'Problemas técnicos');

/* ------------------------------------------------------------------ */
/* 17. HISTORIAL DESCUENTO + CONCURRENCIA                             */
/* ------------------------------------------------------------------ */
INSERT INTO Historial_Descuento (ID_Producto, Fecha_Inicio, Fecha_Fin, Porcentaje_Descuento, Precio_Base_En_Evento, Nombre_Evento) VALUES
(1,'2026-09-01','2026-09-15',25.00,40.00,'Summer Sale'),
(3,'2026-10-01','2026-10-20',15.00,60.00,'Autumn Fest');

INSERT INTO Registro_Concurrencia (ID_Producto, Fecha_Registro, Pico_Maximo_Jugadores) VALUES
(1,'2026-10-01',1200),
(1,'2026-10-02',1350),
(3,'2026-10-01',45000),
(3,'2026-10-02',48000),
(5,'2026-10-01',800000),
(2,'2026-10-01',3000);

/* ------------------------------------------------------------------ */
/* 18. GALERÍA + CARRITO + LISTA DESEOS (mínimo)                      */
/* ------------------------------------------------------------------ */
INSERT INTO Galeria_Multimedia (ID_Producto, ID_Multimedia, URL_Archivo, Tipo_Archivo) VALUES
(1,1,'https://cdn.conesteam/sims4_1.jpg','Foto'),
(1,2,'https://cdn.conesteam/sims4_2.jpg','Foto'),
(3,1,'https://cdn.conesteam/elden_1.jpg','Foto'),
(3,2,'https://cdn.conesteam/elden_trailer.mp4','Video');

INSERT INTO Carrito (ID_Usuario, ID_Producto, Fecha_Agregado) VALUES
(4,8,'2026-10-20'),
(5,5,'2026-10-21');

INSERT INTO Lista_Deseos (ID_Usuario, ID_Producto, Fecha_Agregado, Notificar_Descuento) VALUES
(1,3,'2026-09-01',1),
(2,4,'2026-09-05',1);

PRINT 'Inserts mínimos cargados. Listo para probar Queries y Programmability.';
GO

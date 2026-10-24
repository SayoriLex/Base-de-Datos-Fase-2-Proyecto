
DROP TABLE IF EXISTS Historial_Descuento;
DROP TABLE IF EXISTS Registro_Concurrencia;
DROP TABLE IF EXISTS Reembolso;
DROP TABLE IF EXISTS Detalle_Factura;
DROP TABLE IF EXISTS Factura;
DROP TABLE IF EXISTS Metodo_Pago;
DROP TABLE IF EXISTS Desbloqueo_Logro;
DROP TABLE IF EXISTS Biblioteca;
DROP TABLE IF EXISTS Lista_Deseos;
DROP TABLE IF EXISTS Carrito;
DROP TABLE IF EXISTS Resena;
DROP TABLE IF EXISTS Suscripcion_Mod;
DROP TABLE IF EXISTS Amistad_Usuario;
DROP TABLE IF EXISTS Usuario;
DROP TABLE IF EXISTS Mod ;
DROP TABLE IF EXISTS DLC  ;
DROP TABLE IF EXISTS Galeria_Multimedia;
DROP TABLE IF EXISTS Perfil_Requisito;
DROP TABLE IF EXISTS Logro;
DROP TABLE IF EXISTS Soporte_Idioma ;
DROP TABLE IF EXISTS Producto_Etiqueta ;
DROP TABLE IF EXISTS Juego_Categoria ;
DROP TABLE IF EXISTS Juego_Base ;
DROP TABLE IF EXISTS Idioma ;
DROP TABLE IF EXISTS Empresa_Corporativa;
DROP TABLE IF EXISTS Producto_Digital ;
DROP TABLE IF EXISTS Categoria_Oficial ;
DROP TABLE IF EXISTS Etiqueta_Comunidad ;


--Tablas correspondientes a Catalogo

CREATE TABLE Empresa_Corporativa(
ID_Empresa smallint PRIMARY KEY NOT NULL,
Nombre varchar(25),
Pais_Origen varchar(25),
Fecha_Fundacion date,
ID_Empresa_Matriz smallint,
CONSTRAINT FK_ID_Empresa_Matriz FOREIGN KEY (ID_Empresa_Matriz) references Empresa_Corporativa(ID_Empresa)
);

CREATE TABLE Producto_Digital(
ID_Producto smallint PRIMARY KEY NOT NULL,
Titulo varchar(70),
Descripcion_Corta text,
Descripcion_Larga text,
Fecha_Lanzamiento date,
Tamano_GB DECIMAL(15,2),
Clasificacion_Edad varchar(5),
Precio_Base_Actual smallint,
Tipo_Producto varchar(15),
Metacritic_Score DECIMAL(4,1),
CONSTRAINT Check_Precio_Base CHECK(Precio_Base_Actual >= 0),
CONSTRAINT Check_Tipo_P CHECK(Tipo_Producto IN ('Juego_Base', 'DLC')),
CONSTRAINT Check_Calificacion_E CHECK(Clasificacion_Edad  IN ('E', 'T', 'M', 'AO')),
CONSTRAINT Check_Metacritic_S CHECK(Metacritic_Score >=0 AND Metacritic_Score <=100)
);

CREATE TABLE Galeria_Multimedia(
ID_Producto smallint NOT NULL,
ID_Multimedia smallint NOT NULL,  
URL_Archivo text,
Tipo_Archivo varchar(10),
PRIMARY KEY(ID_Producto,ID_Multimedia),
CONSTRAINT Check_Tipo_A CHECK(Tipo_Archivo IN ('Foto', 'Video')),
CONSTRAINT FK_ID_Producto_Galeria FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Juego_Base(
ID_Producto smallint PRIMARY KEY NOT NULL,
ID_Estudio_Dev smallint,
ID_Publisher smallint,
Motor_Grafico varchar(25),
Tiene_Compras_InGame bit,
Soporta_Cloud_Saves bit,
CONSTRAINT FK_ID_Juego_Base FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto),
CONSTRAINT FK_ID_Estudio_Dev FOREIGN KEY (ID_Estudio_Dev) references Empresa_Corporativa(ID_Empresa),
CONSTRAINT FK_ID_Publisher FOREIGN KEY (ID_Publisher) references Empresa_Corporativa(ID_Empresa)
ON DELETE CASCADE
);

CREATE TABLE DLC(
ID_Producto smallint PRIMARY KEY NOT NULL,
ID_Juego_Base smallint NOT NULL,
Tipo_Contenido varchar(20),
Subtipo_Jugable varchar(20),
CONSTRAINT Check_Tipo_C CHECK(Tipo_Contenido IN('Jugable', 'Banda_Sonora', 'Arte')),
CONSTRAINT Check_Subtipo_J CHECK ((Tipo_Contenido = 'Jugable' AND Subtipo_Jugable IN ('Personaje', 'Mapa', 'Modo_Juego', 'Cosmetico'))
                                 OR (Tipo_Contenido <> 'Jugable' AND Subtipo_Jugable IS NULL)),
CONSTRAINT FK_ID_Producto_DLC FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto),
CONSTRAINT FK_ID_Juego_Base_DLC FOREIGN KEY (ID_Juego_Base) references Juego_Base(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Perfil_Requisito(
ID_Producto smallint NOT NULL,
Tipo_Perfil varchar(20) NOT NULL,
Sistema_Operativo varchar(25),
Procesador varchar(40),
Memoria_RAM smallint,
Tarjeta_Grafica varchar(40),
PRIMARY KEY(ID_Producto, Tipo_Perfil),
CONSTRAINT Check_Tipo_Perfil CHECK(Tipo_Perfil IN ('Minimo', 'Recomendado')),
CONSTRAINT FK_ID_Producto_P FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Logro(
ID_Juego_Base smallint NOT NULL,
ID_Logro smallint NOT NULL,
Nombre_Logro varchar(40),
Descripcion_Logro text,
Es_Secreto bit,
PRIMARY KEY(ID_Juego_Base,ID_Logro),
CONSTRAINT FK_ID_JB_Logro FOREIGN KEY (ID_Juego_Base) references Juego_Base(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Categoria_Oficial(
ID_Categoria smallint PRIMARY KEY NOT NULL,
Nombre_Categoria varchar(30),
Descripcion_Categoria text
);

CREATE TABLE Juego_Categoria(
ID_Producto smallint NOT NULL,
ID_Categoria smallint NOT NULL,
PRIMARY KEY(ID_Producto,ID_Categoria),
CONSTRAINT FK_ID_Producto_Juego_Categoria FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto),
CONSTRAINT FK_ID_Categoria FOREIGN KEY (ID_Categoria) references Categoria_Oficial(ID_Categoria)
ON DELETE CASCADE
);

CREATE TABLE Idioma(
ID_Idioma smallint PRIMARY KEY NOT NULL,
Nombre_Idioma text
);

CREATE TABLE Soporte_Idioma(
ID_Producto smallint NOT NULL,
ID_Idioma smallint NOT NULL,
Soporta_Interfaz bit,
Soporta_Audio bit,
Soporta_Subtitulos bit,
PRIMARY KEY(ID_Producto, ID_Idioma),
CONSTRAINT FK_ID_Producto_Soporte_Idioma FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto),
CONSTRAINT FK_ID_Idioma FOREIGN KEY (ID_Idioma) references Idioma(ID_Idioma)
ON DELETE CASCADE
);

CREATE TABLE Etiqueta_Comunidad(
ID_Etiqueta smallint PRIMARY KEY NOT NULL,
Nombre_Etiqueta varchar(30)
);

CREATE TABLE Producto_Etiqueta(
ID_Producto smallint NOT NULL,
ID_Etiqueta smallint NOT NULL,
Cantidad_Votos smallint,
PRIMARY KEY(ID_Producto, ID_Etiqueta),
CONSTRAINT FK_ID_Producto_P_Etiqueta FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto),
CONSTRAINT FK_ID_Etiqueta FOREIGN KEY (ID_Etiqueta) references Etiqueta_Comunidad(ID_Etiqueta)
ON DELETE CASCADE
);

CREATE TABLE Mod(
ID_Producto_Base smallint NOT NULL,
ID_Mod smallint NOT NULL,
Nombre_Mod varchar(30),
Descripcion_Mod text,
Tamano_MB smallint,
PRIMARY KEY(ID_Producto_Base, ID_Mod),
CONSTRAINT FK_ID_Producto_Base_Mod FOREIGN KEY (ID_Producto_Base) references Juego_Base(ID_Producto)
ON DELETE CASCADE
);

--Tablas correspondientes a Usuarios 

CREATE TABLE Usuario(
ID_Usuario smallint PRIMARY KEY NOT NULL,
Nickname varchar(50),
Correo text,
Contrasena_Hash varchar(30),
Fecha_Nacimiento date,
Fecha_Registro date,
Pais_Residencia varchar(30),
Estado_Cuenta varchar(15),
CONSTRAINT Check_Estado_C CHECK(Estado_Cuenta IN ('Activa', 'Suspendida', 'Baneada'))
);

CREATE TABLE Amistad_Usuario(
ID_Usuario_Solicitante smallint NOT NULL,
ID_Usuario_Receptor smallint NOT NULL,
Fecha_Amistad date,
Estado_Amistad varchar(15),
PRIMARY KEY(ID_Usuario_Solicitante, ID_Usuario_Receptor),
CONSTRAINT Check_Estado_A CHECK(Estado_Amistad IN ('Pendiente', 'Aceptada', 'Bloqueada')),
CONSTRAINT FK_UsuarioS FOREIGN KEY (ID_Usuario_Solicitante) references Usuario(ID_Usuario),
CONSTRAINT FK_UsuarioR FOREIGN KEY (ID_Usuario_Receptor) references Usuario(ID_Usuario)
ON DELETE CASCADE
);

CREATE TABLE Desbloqueo_Logro(
ID_Usuario smallint NOT NULL,
ID_Juego_Base smallint NOT NULL,
ID_Logro smallint NOT NULL,
Fecha_Desbloqueo date,
PRIMARY KEY(ID_Usuario, ID_Juego_Base, ID_Logro),
CONSTRAINT FK_Usuario_DLogro FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_Juego_Base_DLogro FOREIGN KEY (ID_Juego_Base) references Juego_Base(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Biblioteca(
ID_Usuario smallint NOT NULL,
ID_Producto smallint NOT NULL,
Horas_Jugadas int,
Fecha_Ultima_Sesion date,
PRIMARY KEY(ID_Usuario, ID_Producto),
CONSTRAINT FK_ID_UBiblioteca FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_ID_PBiblioteca FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Lista_Deseos(
ID_Usuario smallint NOT NULL,
ID_Producto smallint NOT NULL,
Fecha_Agregado date,
Notificar_Descuento bit,
PRIMARY KEY(ID_Usuario, ID_Producto),
CONSTRAINT FK_ID_ULista_Deseos FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_ID_PLista_Deseos FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Carrito(
ID_Usuario smallint NOT NULL,
ID_Producto smallint NOT NULL,
Fecha_Agregado date,
PRIMARY KEY(ID_Usuario, ID_Producto),
CONSTRAINT FK_ID_UCarrito FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_ID_PCarrito FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Resena(
ID_Resena smallint PRIMARY KEY NOT NULL,
ID_Usuario smallint,
ID_Producto smallint,
Texto_Resena text,
Calificacion_1_10 smallint,
Fecha_Publicacion date,
Es_Critica_Especializada bit,
CONSTRAINT Check_Calificacion CHECK(Calificacion_1_10 >=1 AND Calificacion_1_10 <=10),
CONSTRAINT FK_ID_UResena FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_ID_PResena FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Suscripcion_Mod(
ID_Usuario smallint NOT NULL,
ID_Producto_Base smallint NOT NULL,
ID_Mod smallint NOT NULL,
Fecha_Suscripcion date,
PRIMARY KEY(ID_Usuario, ID_Producto_Base, ID_Mod),
CONSTRAINT FK_ID_U_SuscripcionMod FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_ID_Mod_SuscripcionM FOREIGN KEY (ID_Producto_Base, ID_Mod) references Mod(ID_Producto_Base,ID_Mod)
ON DELETE CASCADE
);

--Tablas referentes a Comercio

CREATE TABLE Metodo_Pago(
ID_Metodo_Pago smallint PRIMARY KEY NOT NULL,
Nombre_Metodo varchar(20),
Moneda varchar(10),
Requiere_Validacion bit
);

CREATE TABLE Factura(
ID_Factura smallint PRIMARY KEY NOT NULL,
Codigo_Transaccion smallint,
Fecha_Hora_Emision datetime,
Sub_Total DECIMAL(20,2),
Monto_Descuento DECIMAL(20,2),
Monto_Impuesto DECIMAL(20,2),
Total_Pagado DECIMAL(20,2),
ID_Usuario smallint,
ID_Metodo_Pago smallint,
CONSTRAINT Check_Sub_Total CHECK(Sub_Total  >= 0),
CONSTRAINT Check_Total_Pagado CHECK(Total_Pagado  >= 0),
CONSTRAINT FK_ID_UFactura FOREIGN KEY (ID_Usuario) references Usuario(ID_Usuario),
CONSTRAINT FK_ID_MetodoP_Factura FOREIGN KEY (ID_Metodo_Pago) references Metodo_Pago(ID_Metodo_Pago)
ON DELETE CASCADE
);

CREATE TABLE Detalle_Factura(
ID_Factura smallint NOT NULL,
ID_Producto smallint NOT NULL,
Precio_Venta_Historico DECIMAL(20,2),
Descuento_Aplicado_Pct DECIMAL(20,2),
PRIMARY KEY(ID_Factura, ID_Producto),
CONSTRAINT FK_ID_Factura_DetalleF FOREIGN KEY (ID_Factura) references Factura(ID_Factura),
CONSTRAINT FK_ID_PDetalle_Factura FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Reembolso(
ID_Reembolso smallint PRIMARY KEY NOT NULL,
ID_Factura smallint,
ID_Producto smallint,
Fecha_Reembolso date,
Monto_Reembolsado DECIMAL(20,2),
Motivo text,
CONSTRAINT Check_Monto_Reembolsado CHECK(Monto_Reembolsado  >= 0),
CONSTRAINT FK_ID_FReembolso FOREIGN KEY (ID_Factura) references Factura(ID_Factura),
CONSTRAINT FK_ID_PReembolso FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

--Tablas referentes a ConeSTeam Data Analytics

CREATE TABLE Historial_Descuento(
ID_Producto smallint NOT NULL,
Fecha_Inicio date NOT NULL,
Fecha_Fin date,
Porcentaje_Descuento DECIMAL(20,2),
Precio_Base_En_Evento DECIMAL(20,2),
Nombre_Evento varchar(40),
PRIMARY KEY (ID_Producto, Fecha_Inicio),
CONSTRAINT Check_Porcentaje_D CHECK(Porcentaje_Descuento >=0 AND Porcentaje_Descuento <=100),
CONSTRAINT Check_Comparar_Fechas CHECK(Fecha_Fin >= Fecha_Inicio),
CONSTRAINT FK_ID_PHistorial FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

CREATE TABLE Registro_Concurrencia(
ID_Producto smallint NOT NULL,
Fecha_Registro date NOT NULL,
Pico_Maximo_Jugadores int,
PRIMARY KEY(ID_Producto, Fecha_Registro),
CONSTRAINT FK_ID_PRegistro FOREIGN KEY (ID_Producto) references Producto_Digital(ID_Producto)
ON DELETE CASCADE
);

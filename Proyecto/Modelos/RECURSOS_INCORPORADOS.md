# Recursos incorporados del proyecto del companero

Se conservaron las geometrías y texturas de los GLB originales. Se reorganizaron las rutas y las escenas para integrarlas con los sistemas actuales. Las licencias y autores siguientes proceden de los metadatos incluidos en cada archivo.

## Organizacion e integracion

- Planetas: modelos en `Proyecto/Modelos/Planetas/` y escenas en `Proyecto/Escenas/Planetas/`. Se incorporaron los cinco planetas colocados por el companero y Marte, que tambien estaba incluido entre sus archivos. Los nombres Asteria y Nereida identifican los modelos originalmente llamados `planet.glb` y `planet (1).glb`.
- Interior: modelos en `Proyecto/Modelos/Muebles/` y composicion en `Proyecto/Escenas/Interior/DecoracionNave.tscn`. Se conservaron las posiciones originales de los nueve muebles y conjuntos decorativos.
- Colisiones: formas fisicas simplificadas en `Proyecto/Modelos/Muebles/Colisiones/`, cargadas por `Proyecto/Codigos/Interior/colisiones_muebles.gd`. Conservan los huecos de los muebles y evitan recalcular mallas grandes durante el juego.
- Rocky: modelo en `Proyecto/Modelos/Mascotas/Rocky/`, escena en `Proyecto/Escenas/Mascotas/` y seguimiento en `Proyecto/Codigos/Mascotas/`. Se conecto el seguimiento que estaba sin referencias en la otra copia y se adapto a pilotaje, pausa y viajes planetarios.
- Audio: `Proyecto/Sonidos/Ambiente/AmbienteJuego.tscn` reutiliza la pista `bckgmusic.mp3` incluida en ambas copias, en bucle y con volumen independiente en las opciones. La otra copia no incluia una segunda pista de ambiente.
- Se conservaron el personaje, los materiales, las animaciones en bucle, los controles contextuales, las misiones, el planificador, la mochila, la nave y los ajustes avanzados de la version actual.

## Modelos y atribuciones

## Planet

- Archivo: `Proyecto/Modelos/Planetas/Asteria/asteria.glb`
- Autor: PounUP (https://sketchfab.com/PounUP)
- Licencia: CC-BY-NC-4.0 (http://creativecommons.org/licenses/by-nc/4.0/)
- Fuente: https://sketchfab.com/3d-models/planet-0104234961624b7aa0cb85d03161babe

## Planet

- Archivo: `Proyecto/Modelos/Planetas/Nereida/nereida.glb`
- Autor: Werdiki (https://sketchfab.com/Werdiki)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/planet-dc2bc401c5e1455dbf75e38f2b3224d0

## lava planet

- Archivo: `Proyecto/Modelos/Planetas/Lava/lava.glb`
- Autor: jcises (https://sketchfab.com/jcises)
- Licencia: CC-BY-NC-4.0 (http://creativecommons.org/licenses/by-nc/4.0/)
- Fuente: https://sketchfab.com/3d-models/lava-planet-f266cfb9baab4f7390c08724aea78b5b

## Imaginary planet #1

- Archivo: `Proyecto/Modelos/Planetas/Imaginario/imaginario.glb`
- Autor: czifra.mate (https://sketchfab.com/czifra.mate)
- Licencia: CC-BY-NC-4.0 (http://creativecommons.org/licenses/by-nc/4.0/)
- Fuente: https://sketchfab.com/3d-models/imaginary-planet-1-f6e6cdd89b0c4ed5a651b65e58ac6c3e

## The Last Reality - Cube Planet - 8K

- Archivo: `Proyecto/Modelos/Planetas/Cubico/cubico.glb`
- Autor: The Realm Genō (https://sketchfab.com/TheRealmGeno)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/the-last-reality-cube-planet-8k-b8cc00ed1b0343e39c61e266077a3259

## Marte

- Archivo: `Proyecto/Modelos/Planetas/Marte/marte.glb`
- Autor: uperesito (https://sketchfab.com/uperesito)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/marte-cec3fdf051504d7984dd52a950416261

## Project Hail Mary Rocky

- Archivo: `Proyecto/Modelos/Mascotas/Rocky/rocky.glb`
- Autor: Abrazafarolas (https://sketchfab.com/Abrazafarolas)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/project-hail-mary-rocky-853f49d0b6a7416b8b7c48c619d01798

## Bathroom asset part 3

- Archivo: `Proyecto/Modelos/Muebles/Bano/ducha.glb`
- Autor: SofiaWolfie (https://sketchfab.com/SofiaWolfie)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/bathroom-asset-part-3-ad4eec7c47f14f7682e60469d96255a4

## Habitacion

- Archivo: `Proyecto/Modelos/Muebles/Habitacion/habitacion.glb`
- Autor: Artist Cone (https://sketchfab.com/artistcone)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/habitacion-f1e8d5dee4254a52a26551a7ac7eb4c9

## CAMA DATHUS ZEEA AGAVE CASA

- Archivo: `Proyecto/Modelos/Muebles/Cama/cama.glb`
- Autor: Grupo Oca (https://sketchfab.com/grupooca)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/cama-dathus-zeea-agave-casa-5244f3feab1342c2afa332fe4a05eb00

## console03b

- Archivo: `Proyecto/Modelos/Muebles/Consola/consola.glb`
- Autor: ~Drift~ (https://sketchfab.com/QuickDriftVR)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/console03b-a7301efe05454ed38c257524137b0045

## UNIVAC Computer

- Archivo: `Proyecto/Modelos/Muebles/Computadora/computadora.glb`
- Autor: sudreyskr (https://sketchfab.com/sudreyskr)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/univac-computer-2a5241d9d24c4e129d6dadc0b0734006

## Mesa De Trabajo Junio 2025 V1

- Archivo: `Proyecto/Modelos/Muebles/MesaTrabajo/mesa_trabajo.glb`
- Autor: davidmarinv504 (https://sketchfab.com/davidmarinv504)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/mesa-de-trabajo-junio-2025-v1-8e2ee15ae5ae45b385ac977dfa5069ae

## Tool container (lowpoly)

- Archivo: `Proyecto/Modelos/Muebles/ContenedorHerramientas/contenedor.glb`
- Autor: Zuckergelee (https://sketchfab.com/knorke)
- Licencia: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Fuente: https://sketchfab.com/3d-models/tool-container-lowpoly-aff5e7e9545a4bf3b4366fc1102a20a9

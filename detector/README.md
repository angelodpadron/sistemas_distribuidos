# Informe de practica: Detector (Sistemas Distribuidos)

## Observaciones usando diferentes nodos

### Detalles de la prueba


Se utilizaron dos nodos, `node0` y `node1`. Ambos nodos fueron ejecutados en un mismo host. 

El `node0` se encargo de ejecutar `consumer`, y `node1` el `producer`. Este ultimo fue configurado para responder cada 1000 ms.

Una vez que `producer` fue puesto en servicio, desde el `nodo0` se inicializo el proceso de `consumer` pasandole una tupla con el nombre registrado del proceso `producer` y el nombre del nodo correspondiente: `consumer:start({producer, 'node1@DRAGON-PC'})`

### Ejecucion

![ejecucion](https://iili.io/HvdrYla.jpg)

### Manejo de errores

#### Detencion del proceso `producer`

Mediante el uso de monitores, `consumer` puede detectar fallas en el proceso `producer` que esta enviandole mensajes.
Para simular dicha falla, el `producer` tiene implementado la funcion `crash/1` que genera un error y detiene el proceso.
Al ejecutar `crash/1`, `producer` detecta el error y imprime los detalles del mismo en su terminal:

![falla](https://iili.io/Hvd6Raa.jpg)


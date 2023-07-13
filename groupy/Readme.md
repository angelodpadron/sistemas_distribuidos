# Informe de practica: Groupy (Sistemas Distribuidos)


## Arquitectura general

El sistema Groupy esta compuesto con los siguientes modulos:

- **(gsm1)**: Modulo que permite hacer multicast a un grupo con un lider que orquestre la correcta secuencia de entrega de los mensajes.
- **(gsm2)**: Igual que el modulo anterior pero se agrega el monitoreo al nodo con rol de lider. Si se detecta la caida de este, la eleccion del nuevo lider sera el primer nodo en el array de esclavos.
- **(gsm3)**: En este modulo se agrega un registro del ultimo mensaje recibido para entrega en cada uno de los esclavos. De esta forma, en caso de que se caiga el lider, el ultimo mensaje recibido por el nuevo lider se retransmitira para que no haya una posible perdida.



## Manejando errores
### Detectores de fallas
Algo que debemos prestar atención es que debemos hacer si, como esclavo, recibimos un mensaje de vista de un nuevo líder antes que hayamos detectado que el viejo líder murió. 
- Deberíamos negarnos a manejar mensajes de vista a menos que hayamos visto un mensaje _Down_ del líder? o simplemente deberíamos aceptar el mensaje del nuevo líder e ignorar el mensaje _Down_?
  
      En este caso seria conveniente conte controlar que los mensajes de 'view' recibidos sean de insercion de un nuevo esclavo o cambio de lider, ya que a pesar de no detectar una caida del lider podriamos recibir estos mensajes para agregar nodos al array.



## Qué podría salir mal?
Lo primero que debemos darnos cuenta es que garantiza Erlang en el envío de mensajes. La especificación garantiza solo que los mensajes son entregados en orden FIFO, no que necesariamente lleguen. Nosotros construimos nuestro sistema basados en la entrega confiable de mensajes, algo que no está garantizado.
- Cómo deberíamos cambiar nuestra implementación para manejar la posibilidad de que se pierda un mensaje? Cuál sería el impacto de esto en la performance?
  
      Para garantizar una entrega confiable, deberia existir algun tipo de confirmacion de recepcion de los mensajes y prevenir la entrega de mensajes nuevos. Pero esto trae otros problemas, como ser la posibilidad que se pierda el mensaje de confirmacion de recepcion haciendo que se crezca el buffer de mensajes pendientes de entrega o que se bloquee el proceso de broadcast.
  
La segunda razón por la cual las cosas no funcionan es que nos basamos que la detección de fallas de Erlang es perfecto, esto es, que nunca va a sospechar que un nodo correcto ha muerto. 
- Es esto siempre así? Podemos adaptar el sistema para que se comporte correctamente si hay progreso, aún cuando podría no siempre tener progreso?
  
      Una posibilidad seria agregar un 'healthcheck' que cada determinada cantidad de tiempo envie un mensaje y aguarde la respuesta para validar que los nodos se encuentran saludables. La complejidad del metodo esta en definir que acciones tomar en caso de no recibir respuesta de algun nodo, porque podria ser el caso en que haya demora en la red y se perciba como una caida.
  
La tercer razón de por qué las cosas no funcionan es que podemos tener una situación donde un nodo incorrecto entrega un mensaje que no fue entregado por ningún nodo correcto. Esto puede suceder aún si tenemos envío confiable y detección de fallas perfecta. 
- Cómo podría pasar esto y cuán seguido? Cómo sería una solución?
  
      Esta situacion podria darse si un nodo lider se cae y se vuelve a levantar retomando el estado del proceso en el que se quedo. El resto de los nodos del cluster no lo tendran en la lista pero el si los tendra a ellos, permitiendo que envie mensajes. Una forma de detectar este caso es controlando el mensaje 'msg' en los nodos con rol de lider, ya que nunca deberian recibirlo de un esclavo. Y una forma de solucionarlo seria enviando un identificador de remitente para ignorar mensajes enviados por nodos fuera del scope.


# Informe de practica: Loggy (Sistemas Distribuidos)

## Test de ejecucion
  Corramos algunos tests y tratemos de encontrar mensajes de log que sean mostrados fuera de orden.
  ¿Cómo sabemos que fueron impresos fuera de orden?
>    Los identificadores de mensaje deberian listarse en un par 'received'/'sending' consecutivos pero no nos garantiza que se listen en orden.

  Experimentemos con el jitter y veamos si podemos incrementar o decrementar (¿eliminar?) el numero de entradas incorrectas.
>    Con 100ms de jitter ya podemos ver que los mensajes comienzan a listarse desordenados.

## Tiempos logicos de Lamport
  Hagamos algunos tests e identifiquemos situaciones donde las entradas de log sean impresas en orden incorrecto. 
  ¿Cómo identificamos mensajes que estén en orden incorrecto?
>    La representacion del tiempo que estamos usandon no garantiza que que imprima la secuencia correcta en la que se enviaron/recibieron los mensajes, asi que sigue siendo dificil darse cuenta que los mensajes esten en el orden correcto.

  ¿Qué es siempre verdadero y qué es a veces
verdadero? 
>    Es siempre verdadero que los mensajes enviados entre workers van a estar ordenados, permitiendo un ordenamiento de causalidad entre dichos workers. Sin embargo, esta relacion de causalidad puede verse afectada cuando un worker deja de responder a otros por fallas o causas externas.

  ¿Cómo lo hacemos seguro?
>    Tenemos que mantener un registro de los clock que fue enviando cada nodo antes de imprimir los logs.

## La parte delicada
  Debemos de alguna manera mantener una cola de retención de mensajes que no podemos entregar aun porque no sabemos si recibiremos un mensaje con un timestamp anterior.
  ¿Cómo sabemos si los mensajes son seguros de imprimir
>    Para esto debemos saber si el reloj del mensaje que estamos queriendo loggear es menor o igual al reloj de los demas nodos, tendriamos llevar un registro del reloj de cada nodo para saber si el mensaje es seguro de imprimir.

## En el curso
  También debemos escribir un reporte que describa el módulo
time (por favor no escribir una página de código fuente;
describirlo con sus propias palabras). Describir si encontraron entradas fuera de orden en la primera implementación y en caso afirmativo, cómo fueron detectadas.
  ¿Qué es lo que el log final nos muestra?
>    Nos muestra los mensajes que fueron seguros de imprimir segun la interaccion que tuvo cada nodo en el cluster.

  ¿Los eventos ocurrieron en el mismo orden en que son presentados en el log?
>    No necesariamente, los mensajes que fueron impresos con un mismo reloj pueden estar desordenados segun el tiempo en que se originaron. Para resolver esto podriamos buscar una implementacion que actualice el reloj de los nodos a pesar de que no generen un nuevo evento.

  ¿Que tan larga será la cola de retención?
>    La cola retendra todos los mensajes de los nodos con un reloj mayor al ultimo mensaje del nodo con reloj mas bajo. Esto va a depender de la frecuencia con la que interactuen todos los nodos en el cluster.

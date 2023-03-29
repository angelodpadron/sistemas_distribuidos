# Informe de practica: Rudy (Sistemas Distribuidos)

## Observaciones al hacer requests al nodo ejecutando el servidor

### Cantidad de requests por segundo

Promediando el tiempo total de 5 ejecuciones del bench, el cual consiste en realizar 100 requests al servidor, y sin un delay configurado en el mismo, el tiempo promedio para completar cada ejecución es de ~215,94 ms.
Basándose en ese promedio, en 1 segundo, hipotéticamente, se pueden completar aproximadamente 465 requests.

### Implicaciones al implementar un delay al responder requests

Al implementar un delay de 40 ms al generar responses en el servidor, el promedio del punto anterior incrementa más de un 2000%, pasando de los ~215,94 ms a los ~4731,70 ms.


### Múltiples instancias del benchmark

Al ejecutar el benchmark desde más de una máquina*, y siendo que el servidor no implementa ninguna paralelización para el manejo de responder requests, los tiempo se ven casi duplicados respecto a los tiempos obtenidos en el punto anterior:

![Bench result](https://iili.io/HNZAzOB.png)

(*) En realidad es en una misma maquina pero desde diferentes nodos


### Manejo de requests mediante concurrencia. ¿Se debería crear un nuevo proceso por cada request de entrada? ¿Toma tiempo para crear un nuevo proceso? ¿Qué ocurriría si se tiene miles de requests por minuto?

Es una buena forma de resolver el problema de concurrencia si se utiliza en un ambiente controlado, ya que el crecimiento de la cantidad de procesos depende de las requests simultáneas que se estén procesando. Si bien levantar un proceso nuevo es inmediato, la cantidad de procesos en simultáneo pueden impedir el correcto funcionamiento del servidor. Además habría que controlar la cantidad de requests procesadas de un mismo origen para evitar algún ataque de DDOS.


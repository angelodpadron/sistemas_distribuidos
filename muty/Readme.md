# (BORRADOR)
# Informe de practica: Muty (Sistemas Distribuidos) 

## Intento de resolución de safety y liveness

## Lock2

### Problema de Lock1


El modulo lock1 asegura que solo un worker pueda acceder a la seccion critica a la vez, sin embargo la implementacion no asegura que todos los workers accedan al lock antes del timeout, haciendo que el worker intentando se "rinda" y reinicie su ejecucion.

### Logica de Lock2

Para intentar solucionar este problema, se implemento un modulo lock2, el cual extiende la logica de lock1 agregando un sistema de prioridades. Cada worker utiliza su id como prioridad, y el worker con la prioridad mas alta es el primero en acceder al lock. Cuando un lock en espera recibe un request de otro lock con mayor prioridad, este le da el "ok" inmediatamente en lugar de retenerlo hasta recibir un mensaje de release.

### Problemas

La implementacion actual permite que mas de un worker pueda acceder a la seccion critica, por lo tanto no es una solucion completa al problema, de hecho lo empeora con respecto a lo que ofrece lock1. 

(pendiente agregar mas detalles)

## Intento de resolución de safety, liveness y fairness

## Lock3

### Problema de Lock2

### Logica de Lock3

### Problemas
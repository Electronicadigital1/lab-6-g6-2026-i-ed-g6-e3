
#  <img src="/Lab2.jpg" width="1000">

## Integrantes 

- **Ana María Garnica Vargas cc.1098506060** 
- **Diego Alejandro Garzon Niño cc.1069256890** 
- **Kevin Santiago Umaña Cervera cc.112211939** 
**Junio 2026**
# Informe

Indice:

1. [Diseño implementado](#diseño-implementado)
2. [Simulaciones](#simulaciones)
3. [Implementación](#implementación)
4. [Conclusiones](#conclusiones)
5. [Referencias](#referencias)

## Diseño implementado
### Descripción

### Diagramas


## Simulaciones 

<!-- (Incluir las de Digital si hicieron uso de esta herramienta, pero también deben incluir simulaciones realizadas usando un simulador HDL como por ejemplo Icarus Verilog + GTKwave) -->


## Implementación


## Conclusiones


## Referencias

<h1>Análisis del controlador LCD1602 en Verilog</h1>

<p>
El presente módulo implementa un controlador para una pantalla LCD1602 utilizando una FPGA.
Su función principal consiste en leer un valor binario de 8 bits proveniente de interruptores
(<code>sw[7:0]</code>), convertir dicho valor a formato decimal y posteriormente mostrarlo en la
pantalla LCD junto con el texto <b>"Bateria"</b>. Para lograrlo, el diseño se divide en cuatro
bloques funcionales principales: generación del reloj de comunicación, procesamiento de entradas,
máquina de estados y visualización en la LCD.
</p>

<hr>

<h2>1. Generación del reloj de 16 ms y señales de control de la LCD</h2>

<p>
La pantalla LCD1602 posee tiempos de respuesta significativamente mayores que la frecuencia de
operación de una FPGA. Por esta razón, no es posible transmitir información directamente utilizando
el reloj principal del sistema. Para solucionar este problema se implementa un divisor de frecuencia
que genera una señal mucho más lenta denominada <code>clk_16ms</code>.
</p>

<p>
El bloque utiliza un contador (<code>clk_counter</code>) que incrementa su valor en cada flanco positivo
del reloj principal. Cuando el contador alcanza el valor definido por el parámetro
<code>COUNT_MAX - 1</code>, el contador se reinicia y conmuta el estado de la señal
<code>clk_16ms</code>.
</p>

<pre>
clk principal
      │
      ▼
┌─────────────────┐
│   clk_counter   │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│    clk_16ms     │
└─────────────────┘
      │
      ▼
LCD1602
</pre>

<p>
Esta señal se conecta directamente a la salida <code>enable</code> del módulo LCD. Cada pulso de
habilitación indica a la pantalla que debe capturar el dato o comando presente en el bus de datos.
</p>

<h3>Señales de control utilizadas</h3>

<table>
<tr>
<th>Señal</th>
<th>Descripción</th>
</tr>

<tr>
<td><b>RS</b></td>
<td>
Selecciona el tipo de información enviada.
<ul>
<li>RS = 0 → Comando.</li>
<li>RS = 1 → Dato ASCII.</li>
</ul>
</td>
</tr>

<tr>
<td><b>RW</b></td>
<td>
Selecciona el modo de operación.
<ul>
<li>RW = 0 → Escritura.</li>
<li>RW = 1 → Lectura.</li>
</ul>
En este diseño permanece permanentemente en modo escritura.
</td>
</tr>

<tr>
<td><b>Enable</b></td>
<td>
Pulso de habilitación utilizado para que la LCD capture la información presente en el bus de datos.
</td>
</tr>

<tr>
<td><b>Data[7:0]</b></td>
<td>
Bus de datos de 8 bits que contiene comandos o caracteres ASCII.
</td>
</tr>

</table>

<p>
Este bloque garantiza que toda la comunicación con la LCD se realice respetando las restricciones
temporales impuestas por el dispositivo.
</p>

<hr>

<h2>2. Entradas, conversión binario–decimal–ASCII y detección de cambios</h2>

<p>
La información mostrada en la pantalla proviene de los interruptores conectados a la entrada
<code>sw[7:0]</code>. Estos ocho bits representan un número binario sin signo cuyo rango es:
</p>

<pre>
0 ≤ sw ≤ 255
</pre>

<p>
Sin embargo, la pantalla LCD únicamente puede representar caracteres ASCII, por lo que es necesario
realizar una conversión previa.
</p>

<h3>Conversión binario a decimal</h3>

<p>
El valor binario se descompone en centenas, decenas y unidades utilizando operaciones aritméticas:
</p>

<pre>
centenas = sw / 100;
decenas  = (sw % 100) / 10;
unidades = sw % 10;
</pre>

<p>
Por ejemplo:
</p>

<pre>
sw = 153

centenas = 1
decenas  = 5
unidades = 3
</pre>

<h3>Conversión decimal a ASCII</h3>

<p>
Cada dígito decimal debe transformarse en un carácter ASCII. Esto se logra sumando el código ASCII
del carácter '0'.
</p>

<pre>
ascii_centena = centenas + "0";
ascii_decena  = decenas  + "0";
ascii_unidad  = unidades + "0";
</pre>

<p>
Para el ejemplo anterior:
</p>

<pre>
1 → '1'
5 → '5'
3 → '3'
</pre>

<p>
El resultado final es la cadena:
</p>

<pre>
"153"
</pre>

<h3>Detección de cambios</h3>

<p>
El sistema almacena el último valor mostrado utilizando el registro:
</p>

<pre>
sw_old
</pre>

<p>
Posteriormente compara continuamente el valor actual con el almacenado:
</p>

<pre>
sw_changed = (sw != sw_old);
</pre>

<p>
Si ambos valores son diferentes, la señal <code>sw_changed</code> se activa y solicita una
actualización de la pantalla.
</p>

<pre>
Valor anterior = 45
Valor actual   = 78

sw_changed = 1
</pre>

<p>
Este mecanismo evita reescrituras innecesarias y mejora la eficiencia del sistema.
</p>

<hr>

<h2>3. Máquina de estados finitos (FSM)</h2>

<p>
La máquina de estados es el núcleo de control del controlador LCD. Su función es coordinar la
inicialización del display, la escritura de caracteres y la actualización de la información.
</p>

<h3>Estados implementados</h3>

<pre>
IDLE
CONFIG
WRITE_LINE1
SET_LINE2
WRITE_LINE2
WAIT_CHANGE
SET_LINE1
</pre>

<h3>Diagrama conceptual de funcionamiento</h3>

<pre>
                 ready_i
                    │
                    ▼
┌─────────┐     ┌──────────┐
│  IDLE   │ ──► │ CONFIG   │
└─────────┘     └──────────┘
                    │
                    ▼
             ┌─────────────┐
             │WRITE_LINE1  │
             └─────────────┘
                    │
                    ▼
              ┌──────────┐
              │SET_LINE2 │
              └──────────┘
                    │
                    ▼
             ┌─────────────┐
             │WRITE_LINE2  │
             └─────────────┘
                    │
                    ▼
             ┌─────────────┐
             │WAIT_CHANGE  │
             └─────────────┘
                    │
             sw_changed
                    │
                    ▼
              ┌──────────┐
              │SET_LINE1 │
              └──────────┘
                    │
                    ▼
             ┌─────────────┐
             │WRITE_LINE1  │
             └─────────────┘
</pre>

<h3>Descripción de cada estado</h3>

<h4>IDLE</h4>

<p>
Estado inicial del sistema. La FSM permanece detenida hasta recibir la señal
<code>ready_i</code>.
</p>

<h4>CONFIG</h4>

<p>
Inicializa la LCD enviando los comandos obligatorios:
</p>

<table>
<tr>
<th>Comando</th>
<th>Valor hexadecimal</th>
<th>Función</th>
</tr>

<tr>
<td>FUNCTION_SET</td>
<td>0x38</td>
<td>Configura interfaz de 8 bits y dos líneas.</td>
</tr>

<tr>
<td>ENTRY_MODE</td>
<td>0x06</td>
<td>Incrementa automáticamente el cursor.</td>
</tr>

<tr>
<td>DISPLAY_ON</td>
<td>0x0C</td>
<td>Activa la pantalla.</td>
</tr>

<tr>
<td>CLEAR_LCD</td>
<td>0x01</td>
<td>Limpia la memoria de visualización.</td>
</tr>

</table>

<h4>WRITE_LINE1</h4>

<p>
Escribe el mensaje en la primera línea utilizando el contador
<code>char_counter</code>.
</p>

<h4>SET_LINE2</h4>

<p>
Reposiciona el cursor al inicio de la segunda línea enviando:
</p>

<pre>
0xC0
</pre>

<h4>WRITE_LINE2</h4>

<p>
Escribe el mismo mensaje en la segunda línea de la LCD.
</p>

<h4>WAIT_CHANGE</h4>

<p>
Espera modificaciones en los interruptores.
</p>

<h4>SET_LINE1</h4>

<p>
Reposiciona el cursor al inicio de la primera línea mediante:
</p>

<pre>
0x80
</pre>

<p>
Posteriormente reinicia el proceso de escritura para actualizar la información.
</p>

<hr>

<h2>4. Información enviada a la LCD y ejemplo de funcionamiento</h2>

<p>
La comunicación con la LCD se realiza mediante la transmisión secuencial de comandos y caracteres
ASCII sobre el bus <code>data[7:0]</code>.
</p>

<h3>Comandos enviados durante la inicialización</h3>

<table>
<tr>
<th>Hexadecimal</th>
<th>Función</th>
</tr>

<tr>
<td>0x38</td>
<td>Configuración de interfaz de 8 bits.</td>
</tr>

<tr>
<td>0x06</td>
<td>Incremento automático del cursor.</td>
</tr>

<tr>
<td>0x0C</td>
<td>Activación del display.</td>
</tr>

<tr>
<td>0x01</td>
<td>Limpieza de pantalla.</td>
</tr>

<tr>
<td>0x80</td>
<td>Inicio línea 1.</td>
</tr>

<tr>
<td>0xC0</td>
<td>Inicio línea 2.</td>
</tr>

</table>

<h3>Mensaje generado</h3>

<p>
El controlador construye la cadena:
</p>

<pre>
Bateria XXX
</pre>

<p>
donde <code>XXX</code> corresponde al valor decimal calculado a partir de los interruptores.
</p>

<h3>Ejemplo 1</h3>

<pre>
sw = 0010 0101
</pre>

<p>
Conversión:
</p>

<pre>
0010 0101₂ = 37₁₀
</pre>

<p>
Contenido mostrado:
</p>

<pre>
Bateria 37
Bateria 37
</pre>

<h3>Ejemplo 2</h3>

<pre>
sw = 1001 1000
</pre>

<p>
Conversión:
</p>

<pre>
1001 1000₂ = 152₁₀
</pre>

<p>
Contenido mostrado:
</p>

<pre>
Bateria 152
Bateria 152
</pre>

<h3>Proceso completo de funcionamiento</h3>

<pre>
SW[7:0]
    │
    ▼
Conversión Binario → Decimal
    │
    ▼
Conversión Decimal → ASCII
    │
    ▼
Detección de cambios
    │
    ▼
Máquina de estados
    │
    ▼
RS, RW, ENABLE, DATA
    │
    ▼
LCD1602
    │
    ▼
Visualización del mensaje
</pre>

<p>
En conclusión, el módulo implementa una arquitectura basada en una máquina de estados finitos que
permite inicializar una pantalla LCD1602, convertir información binaria en texto legible y actualizar
dinámicamente la visualización cada vez que se detecta una modificación en las entradas del sistema.
</p>

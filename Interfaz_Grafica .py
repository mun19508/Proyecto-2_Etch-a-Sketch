from tkinter import *
import serial
import threading
import time
import sys

texto = None
pantalla = None           #se crea la variable sin un valor especifico
x,y = 50,50
ejex,ejey = 128,128       #se le asigna valor inicial a las variables 

def ventana():
    
    #codigo para convertir los strings en entradas
    global canv, puerto, texto,pantalla
    
    pantalla = Tk()
    pantalla.title("Interfaz Gráfica")           #Titulo del programa
    pantalla.geometry("800x800")                 #se crea una pantalla
    texto = StringVar()
    pantalla.config(bg ="blue")                  #la barra donde estan los botones y el label
    canv = Canvas(pantalla, width = 800, height = 600, bg = "white")    #Pantalla donde se dibuja
    canv.pack(fill = "both", expand="True")
    Button(pantalla, text = "Borrar dibujo", command = Delete).pack(side="right")   #boton que sirve para borrar las lineas
    Label(pantalla, text="Ingrese el puerto:").pack()
    puerto = Entry(pantalla, textvariable= texto) #se ingresa el nombre del puerto que se esta usando
    puerto.pack()
    botonDibujar= Button(pantalla, text= "Dibujar", command =  comienzaDibujar   ) #boton que comienza a dibujar
    botonDibujar.pack(side="left")
    
    pantalla.mainloop()
    
def comienzaDibujar(): 
    t1 = threading.Thread(target = Comunicacion, args=(texto.get()  ,))
    t1.start()   #comienza hilo de comunicaion serial
    print(texto.get()) 
    hilo= threading.Thread(target = dibujar)        
    hilo.start()  #comienza como hilo de dibujar
 #funcion que tambien es parte del botonDibujar   

def dibujar():
    global ejex, ejey, x, y, pantalla
    ejex = 120
    ejey = 120
    x = 0
    y = 0
    Px = x
    Py = y
    
    while True:
        Px = x
        Py = y
        print("X: ",x,"Y: ",y)
        if (ejex <= 100):   #si el valor recibido, de x, es menor a 100 
            x = x -1        #se mueve hacia la izquierda 
            
            if x == -1:     #si su posicion es -1, su posicion regresa a 0
                x = 0
            delay = (9/10000)*ejex + 0.01
            time.sleep(delay)
            canv.create_line(Px,Py,x,y, fill = "red")        
        if 155 <= ejex:      #si el valor recibido, de x, es mayor a 155   
            x = x + 1        #se mueve hacia la izquierda
            if x >= 800:     #si su posicion es mayor a 800, su posicion retorna a 800 
                x = 800 
            delay = (-9/10000)*(ejex-155)+ 0.1
            time.sleep(delay)
            canv.create_line(Px,Py,x,y, fill = "red")
            
        if ejey <= 100:      #la logica de dibujar en el eje y, es igual a a la de x
                y = y + 1    #pero con distinto espacio de dibujo, ver linea 22
                if y >= 600:
                    y = 600
                delay = (9/12400) * ejey +0.01
                time.sleep(delay)
                canv.create_line(Px,Py,x,y, fill = "red")
        if 155 <= ejey:      
                y = y - 1
                if y == -1:  
                    y = 0
                delay = (-9/10000) * (ejey - 155) + 0.1
                time.sleep(delay)
                canv.create_line(Px,Py,x,y, fill = "red")
        
        pantalla.update_idletasks()  
        pantalla.update()    #se actualizado la pantalla


def Delete():
    global canv
    canv.delete("all")
    return        
#funcion que tambien es parte del boton de borrar

def Comunicacion(name):
    global x,y,ejey,ejex
    pic = serial.Serial(port=name, baudrate=9600, parity = serial.PARITY_NONE,stopbits=serial.STOPBITS_ONE,bytesize= serial.EIGHTBITS,timeout = 0)
    pic.flushInput()
    pic.flushOutput()
    #funcion que esta relacionado con la comunicacion serial    
    while True:

        cadenax = str(x)
        cadenay = str(y)

        if len(cadenax)==1:           #con esto se asegura que siempre el valor enviado sea de 3 "cifras"
            cadenax = "00" + cadenax  #si solo tiene unidades se le agrega decenas y centenas
        elif len(cadenax) == 2:
            cadenax = "0" + cadenax   #si solo tiene decenas y unidades se agrega centenas
         
        if len(cadenay)==1:           #misma logica que lo anterior
            cadenay = "00" + cadenay
        elif len(cadenay) == 2:
            cadenay = "0" + cadenay
        
        pic.write((cadenax+","+cadenay+chr(0) ).encode("ascii"))  #se envia la informacion al pic

        pic.flushInput()
            
        time.sleep(0.1) 
        pic.readline()               #lee el valor enviado desde el pic
        read = pic.readline().decode('ascii')
        print("lectura",read)
        valoresxy = read.split(",")  #se separa los valores, leidos.
        ejex = int(valoresxy[0])
        ejey = int(valoresxy[1])
        print(read)
    return
ventana()

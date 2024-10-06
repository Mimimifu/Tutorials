# Criando interfaces com python auto gui

Documentation fork
[Documentation PyAutoGui](https://github.com/Mimimifu/pyautogui)

> Exemplo
#### Ambos os Scripts foram feito e testado no linux entretanto main.py precisa de xwininfo utilitario do linux para pegar as dimesões do aplicativo e clicar nas posições corretas na janela definida !

File named with start.py
```

from tkinter import *
from subprocess import *
from pyautogui import *
from time import *
from threading import *
from keyboard import *

proc = None
window = Tk()
window.geometry('400x100')
window.title("Title Application")

def foreverwindowactive(e = ""):
    window.lift()
    window.attributes("-topmost", True)
    #window.focus_get()

    Timer(60, foreverwindowactive).start() // Time set 60 seconds 
    #window.after_idle(window.attributes,'-topmost',False)

def clicked(e = ""):
    global proc
    proc = Popen(['python', 'main.py'])

def kill_task(e = ""):
    if proc and proc.poll() is None:
        print(proc)
        print('killing process ...')
        proc.kill()


bt = Button(window, text="Start", command=clicked)
bt.pack()

stop = Button(window, text="Stop", command=kill_task)
stop.pack()

#Define a callback function for exit
def quit_program(e):
    Timer(0, foreverwindowactive).cancel()
    window.destroy()

Timer(1, foreverwindowactive).start() 
#foreverwindowactive()

window.bind('<F5>', clicked)
window.bind('<F6>', kill_task)
window.bind('<F7>', quit_program)
window.mainloop()

```
File named with main.py
```
#from pywinauto.application import Application

import time
import pyautogui
from subprocess import *
import threading
import keyboard
import mouse
import pyscreeze
import os
 
def on_click(event): 
    print(f"Mouse clicked at: ({event.x}, {event.y})") 
 
def check():
    if keyboard.is_pressed('f6'):
       return 1
    if keyboard.is_pressed('f5'):
       return 0



# Start a new process and specify a path to the text file
#app = Application().start('notepad.exe', timeout=10)
# Connect to already running process:
# By PID
#app = Application(backend="uia").connect(process=1234)
  
# By path to executable
#app = Application(backend="uia").connect(path=r"C:\Windows\System32\Notepad.exe")
  
# By regular expression
#app = Application(backend="uia").connect(title_re=".*Idle Skilling*")
#app.Properties.print_control_identifiers()

def positionWindow():
    command = ['xwininfo', '-name','Idle Skilling']
    result = run(command, stdout=PIPE, stderr=PIPE, universal_newlines=True)
    print(result.returncode, result.stdout, result.stderr)
    if result.returncode == 0:
        #res = result.stdout.replace("\n"," ").split(" ")
        res = result.stdout.replace(" ","").split("\n")
        res = list(filter(None, res)) 
        x = res[1].split(':')
        y = res[2].split(':')
        return int(x[1]),int(y[1])
    else:
        print(result.stderr)
        #return 0,0         

def findImageAndClick(pathImage):
    try:
        #x,y = pyautogui.locateOnScreen(pathImage,region=(0,0, 600, 800))
        x,y = pyautogui.locateOnScreen(pathImage)
        time.sleep(1)
        pyautogui.moveTo(x, y) 
        time.sleep(1)
        pyautogui.click(x,y)
    except:
        print("Image not found "+ pathImage)   

def MoveClickLeft(x,y):
    pyautogui.moveTo(x, y)
    exact = pyautogui.position()
    if exact.x == x and exact.y == y:
        pyautogui.click(x,y)

#global is_on
is_on = True

def change(): 
    global is_on
    MoveClickLeft(243,487)
    """ 
        if is_on:
            threading.Timer(0, attack1).cancel()
            threading.Timer(0, attack2).cancel()
            threading.Timer(0, attack3).cancel()
            threading.Timer(0, attack4).cancel()
            threading.Timer(0, attack5).cancel() 
            threading.Timer(21, buff1).start() 
            threading.Timer(46, buff2).start() 
            threading.Timer(126, buff3).start() 
            threading.Timer(32, buff4).start() 
            threading.Timer(43, buff5).start() 

            is_on = False
        else:
            threading.Timer(0, buff1).cancel() 
            threading.Timer(0, buff2).cancel() 
            threading.Timer(0, buff3).cancel() 
            threading.Timer(0, buff4).cancel() 
            threading.Timer(0, buff5).cancel()         
            threading.Timer(5, attack1).start()
            threading.Timer(25, attack2).start()
            threading.Timer(20, attack3).start()
            threading.Timer(13, attack4).start()
            threading.Timer(26, attack5).start()

            is_on = True
    """  
    print("Change")
    threading.Timer(30, change).start()  

def buff1():
    MoveClickLeft(243,487)
    time.sleep(0.25)    
    MoveClickLeft(312,509)
    time.sleep(0.25) 
    MoveClickLeft(243,487)
    time.sleep(0.25)    
    print("buff Heal")
    threading.Timer(17, buff1).start()  

def buff2(): 
    MoveClickLeft(392,509)
    print("buff Vision")
    threading.Timer(46, buff2).start()  

def buff3(): 
    MoveClickLeft(472,509)
    print("buff Midas")
    threading.Timer(126, buff3).start()  

def buff4(): 
    MoveClickLeft(565,509)
    print("buff Seal")
    threading.Timer(32, buff4).start()  

def buff5(): 
    MoveClickLeft(638,509)
    print("buff Valor")
    time.sleep(0.1)
    threading.Timer(43, buff5).start()   


def attack1(): 
    MoveClickLeft(312,509)
    print("Attack Claw")
    threading.Timer(7, attack1).start()  

def attack2(): 
    MoveClickLeft(392,509)
    print("Attack Poison")
    threading.Timer(28, attack2).start()  

def attack3(): 
    MoveClickLeft(472,509)
    print("Attack Meteor")
    threading.Timer(23, attack3).start()  

def attack4(): 
    MoveClickLeft(565,509)
    print("Attack Flurry")
    threading.Timer(16, attack4).start()  

def attack5(): 
    MoveClickLeft(638,509)
    print("Attack Smite")
    time.sleep(0.1)
    threading.Timer(29, attack5).start()      
"""
    #1
    cooldown = 6
    if int(timeclick) == int(cooldown) : 
        MoveClickLeft(312,509)
        #time.sleep(0.1)
    #2
    cooldown = 27
    if int(timeclick) == int(cooldown) : 
        MoveClickLeft(392,509)
        #time.sleep(0.1)
    #3
    cooldown = 22
    if int(timeclick) == int(cooldown) : 
        MoveClickLeft(472,509)
        #time.sleep(0.1)
    #4
    cooldown = 15
    if int(timeclick) == int(cooldown) : 
        MoveClickLeft(565,509)
        #time.sleep(0.1)
    #5
    cooldown = 28
    if int(timeclick) == int(cooldown) : 
    MoveClickLeft(638,509)
"""


def location(x,y):

    #Begin Show Mob
    MoveClickLeft(883 + x,290 + y)


    #change
    MoveClickLeft(243+x,487+y)

    #time.sleep(0.25)
    #1
    MoveClickLeft(312+x,509+y)
    
    #time.sleep(0.1)
    
    #2
    MoveClickLeft(392+x,509+y)
    time.sleep(0.1)
    #3
    MoveClickLeft(472+x,509+y)
    time.sleep(0.1)
    #4
    MoveClickLeft(565+x,509+y)
    time.sleep(0.1)
    #5
    MoveClickLeft(638+x,509+y)
    time.sleep(0.1)
    """
    """ 
    #change
    MoveClickLeft(243+x,487+y)

    #time.sleep(0.25)


    #1
    MoveClickLeft(312+x,509+y)

    #time.sleep(0.1)
    #2
    MoveClickLeft(392+x,509+y)

    #time.sleep(0.1)
    #3
    MoveClickLeft(472+x,509+y)
    
    #time.sleep(0.1)
    #4
    MoveClickLeft(565+x,509+y)
    
    #time.sleep(0.1)
    #5
    MoveClickLeft(638+x,509+y)
    
    #time.sleep(0.1)
    #Next Mob
    MoveClickLeft(912+x,431+y)
    #lastposition()    
    #time.sleep(0.1)

    #time.sleep(0.1)
    #time.sleep(5)

 
def posi():
    #time.sleep(5)
    xy = pyautogui.position()
    print(xy)
    return xy


def lastposition():
    pyautogui.moveTo(cx, cy)
    #time.sleep(20)
    #time.sleep(0.1)

def timecheck():
    return str(round(time.time(),0)).split('.',1)[0]



#os.system('xwininfo --name "Idle Skilling"')

cx = 0
cy = 0
i = 1 
ftime = 1
while i == 1 : # True
    cx, cy = posi()
    """ 
    if ftime == 1:
        #threading.Timer(17, buff1).start()
        threading.Timer(5, attack1).start()
        threading.Timer(25, attack2).start()
        threading.Timer(20, attack3).start()
        threading.Timer(13, attack4).start()
        threading.Timer(26, attack5).start()
    """
    x,y = positionWindow()
    if !x and !y :
        i = 2
        break    
    location(x,y)
    lastposition()
    time.sleep(6) // It's need !
    ftime = ftime +1
    print("Run: " + str(ftime))





```

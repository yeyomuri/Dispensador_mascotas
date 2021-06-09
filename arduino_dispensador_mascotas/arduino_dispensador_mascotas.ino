#include <ArduinoJson.h>
//#include <Wire.h>
#include<RTClib.h>
#include "BluetoothSerial.h"
#include <Stepper.h>
#include <EEPROM.h> 
#define EEPROM_SIZE 512

// Check if Bluetooth configs are enabled
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

// Bluetooth Serial object
BluetoothSerial SerialBT;

// GPIO where LED is connected to
const int ledPin =  2;
int giro = 0;

String message = "";
String messageStart = "";
char incomingChar;
String temperatureString = "";


StaticJsonDocument<700> doc;
DeserializationError error;

//Parametros(numero de pasos por una revolucion, x, Y{primer par bobina},Z,W{segundo par de bobina})
Stepper MotorPasos1(50, 5, 18, 19, 23); 
const int recorrido_completo = 50; //Cambiar en función del largo de la cortina



//RTC Reloj de tiempo real
RTC_DS3231 rtc;
bool inicio = true; 
bool finalizado = true;

byte i = 0;
byte j = 0;

//------------------------------------------------------Función para grabar en la EEPROM-------------------------------------------------------------
void grabar(int addr, String a) {
  int tamano = a.length(); 
  char inchar[EEPROM_SIZE]; 
  a.toCharArray(inchar, tamano+1);
  for (int i = 0; i < tamano; i++) {
    EEPROM.write(addr+i, inchar[i]);
  }
  for (int i = tamano; i < EEPROM_SIZE; i++) {
    EEPROM.write(addr+i, 255);
  }
  EEPROM.commit();
}

//----------------------------------------------------------Función para leer la EEPROM-------------------------------------------------------------------
String leer(int addr) {
   byte lectura;
   String strlectura;
   for (int i = addr; i < addr+EEPROM_SIZE; i++) {
      lectura = EEPROM.read(i);
      if (lectura != 255) {
        strlectura += (char)lectura;
      }
   }
   return strlectura;
}
//----------------------------------------------------------------------LOOP------------------------------------------------------------------------------
void loop() {
  
  DateTime fecha = rtc.now();
  TimeSpan fechaS = TimeSpan(0, fecha.hour(), fecha.minute(), 0);
  
  // Read received messages (LED control command)
  if (SerialBT.available()){
    char incomingChar = SerialBT.read();
    if (incomingChar != '\n'){
      message += String(incomingChar);
    }
    else{ 
      error = deserializeJson(doc, message);
      if (error) {
        Serial.print(F("deserializeJson() failed: "));
        Serial.println(error.f_str());
        return;
      }
      grabar(0, message);
      message = "";
    }
    Serial.write(incomingChar);  
  }
  //-------------------------------------------------------------PROCESOS DISPENSADOR-------------------------------------------------------------------------
  
  for(i = 0; i < doc["days"].size(); i++){
    if(fecha.dayOfTheWeek() == int(doc["days"][i])){
      //Monitorea los segundos
      //Serial.println(fechaS.totalseconds());
      for(j = 0; j < doc["times"].size(); j++){
        if(fechaS.totalseconds() >= long(doc["times"][j]) && fechaS.totalseconds() <= long(doc["times"][j]) + 180 && inicio == true){   // [3,4) minutos

            digitalWrite(ledPin, HIGH);
            Serial.println(int(doc["amound"][j]));
            giro = 2.5 * int(doc["amound"][j]);
            MotorPasos1.step(giro); //180° * cantidad[j]
            inicio =false;
            digitalWrite(ledPin, LOW);
 
          //Monitore el estado del motor
          //Serial.println(inicio);
        }
        if(fechaS.totalseconds()==long(doc["times"][j]) + 240){//Despues de [4,5) minutos se activara
          inicio = true;
        }
      }
    }
  }
  
  //Serial.println(fechaS.totalseconds());
  delay(20);
}

//---------------------------------------------------------------------setup------------------------------------------------------------------------------------

void setup() {
  pinMode(ledPin, OUTPUT);
  MotorPasos1.setSpeed(30);

  EEPROM.begin(EEPROM_SIZE);
  Serial.begin(115200);
 
  
  // Bluetooth device name
  SerialBT.begin("Homeway_0152");
  Serial.println("The device started, now you can pair it with bluetooth!");
  //RTC 
  if(!rtc.begin()){
    Serial.println("Modulo RC no encontrado");

    while(1);
  }

  //El siguinte bloque(error) esta inactivo en la primera carga del programa
  
  error = deserializeJson(doc, leer(0));
  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.f_str());
    return;
  }
  
  //Desactivar des pues de la primera carga
  //rtc.adjust(DateTime(__DATE__, __TIME__));  
}

#include <smartWaterIons.h>
// Подключение
ionSensorClass sens_A(SOCKET_A);
ionSensorClass sens_B(SOCKET_B);
ionSensorClass sens_C(SOCKET_C);
ionSensorClass sens_D(SOCKET_D);
pt1000Class tempSensor;
// Массивы точек калибровочной концентрации
const float calibs[][3]=
{
  {10.0,  100.0,  1000.0},
  {1.0,   2.0,    3.0}
};

float lastT = 0;
//======================================================================
void setup()
{
  SWIonsBoard.ON();
  USB.ON();  
}

void loop()
{
  if ( millis()-lastT > 10000 )
  {
    SWIonsBoard.ON();
    USB.print(F("<"));
    
    float volts_A = sens_A.read();
    delay(50);
    USB.print(F(" volts_A:"));
    USB.print(volts_A);
    
    float volts_B = sens_B.read();
    delay(50);
    USB.print(F(" | volts_B:"));
    USB.print(volts_B);
    
    float volts_C = sens_C.read();
    delay(50);
    USB.print(F(" | volts_C:"));
    USB.print(volts_C);
    
    float volts_D = sens_D.read();
    delay(50);
    USB.print(F(" | volts_D:"));
    USB.print(volts_D);
    
    float tempValue = tempSensor.read();
    delay(50);
    USB.print(F(" | Temp:"));
    USB.print(tempValue);
    
    USB.print(F(">\n"));
    SWIonsBoard.OFF();
    lastT = millis();
  }
}
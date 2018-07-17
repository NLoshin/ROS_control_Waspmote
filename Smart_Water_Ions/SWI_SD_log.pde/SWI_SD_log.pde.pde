#include <smartWaterIons.h>
char fileIn[64];
char filename[]="DATA_SWI.TXT";
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

long lastT = 0;
void SD_write_part(char metk[8], float data=0){
  sprintf(fileIn,"%f",data);
  strcat (metk,":");
  SD.append(filename,metk);
  SD.append(filename,fileIn);
  SD.append(filename," | ");
  delay(50);
}

void setup()
{
  SWIonsBoard.ON();
  USB.ON();  
  SD.ON();
  SD.del(filename);
  SD.create(filename);
}

void loop()
{
  if ( millis()-lastT > 10000 )
  {
    SWIonsBoard.ON();
    SD_write_part("Time",millis()/1000);
    float volts_A = sens_A.read();
    SD_write_part("A",volts_A);
    float volts_B = sens_B.read();
    SD_write_part("B",volts_B);
    float volts_C = sens_C.read();
    SD_write_part("C",volts_C);
    float volts_D = sens_D.read();
    SD_write_part("D",volts_D);
    float tempValue = tempSensor.read();
    SD_write_part("T",tempValue);
    SD.appendln(filename,".");
    SWIonsBoard.OFF();
    lastT = millis();
  }
}

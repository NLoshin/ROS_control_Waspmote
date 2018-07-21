#include <smartWaterIons.h>
#define USB_DEBUG 1
char buffer[255];
char fileIn[64];
char filename[] = "SWI_LOG.TXT";
#define USB_DEBUG 1
#define T_SENSOR 1
#define A_SENSOR 2
#define B_SENSOR 3
#define C_SENSOR 4
#define D_SENSOR 5
// Подключение
ionSensorClass sens_A(SOCKET_A);
ionSensorClass sens_B(SOCKET_B);
ionSensorClass sens_C(SOCKET_C);
ionSensorClass sens_D(SOCKET_D);
pt1000Class tempSensor;

char *sensName[] = {"TIME", "TEMP", "SENS_A", "SENS_B", "SENS_C", "SENS_D"};
const uint8_t allSensorId[] = {T_SENSOR, A_SENSOR, B_SENSOR, C_SENSOR, D_SENSOR};
// Массивы точек калибровочной концентрации
const float calibs[][3] =
{
  {10.0,  100.0,  1000.0},
  {1.0,   2.0,    3.0}
};

float lastT = 0;
void SD_write_Time() {
  int TT[3];
  TT[2] = (millis() / 1000) % 60;
  TT[1] = (millis() / 60000) % 60;
  TT[0] = (millis() / 3600000);
  snprintf(buffer, sizeof(buffer), "(Time:%dh%dm%ds)", TT[0], TT[1], TT[2]);
  SD.append(filename, buffer);
#ifdef USB_DEBUG
  USB.print("Write to file: ");
  USB.println(buffer);
#endif
}
void SD_write_part(char _metk[], float _data = 0) {
  char s[16];
  dtostrf(_data, 3, 2, s);
  snprintf(buffer, sizeof(buffer), "(%s|%s)", _metk, s);
  SD.append(filename, buffer);
  USB.print("Write to file: ");
  USB.println(buffer);
}

boolean chechId(uint8_t _sensorId) {
  boolean chechIdorId = false;
  for (int i = 0; i < sizeof(allSensorId) / sizeof(uint8_t); i++)
  {
    if (_sensorId == allSensorId[i])
      chechIdorId = true;
  }
  return chechIdorId;
}

float getSensorData (uint8_t _sensorId) {
  float sensorVal;
#ifdef USB_DEBUG
  USB.printf("S: %d ", _sensorId);
#endif
  if ( chechId(_sensorId) )
  {
    switch ( _sensorId )
    {
      case T_SENSOR:
        sensorVal = tempSensor.read();
        break;
      case A_SENSOR:
        sensorVal = sens_A.read();
        break;
      case B_SENSOR:
        sensorVal = sens_B.read();
        break;
      case C_SENSOR:
        sensorVal = sens_C.read();
        break;
      case D_SENSOR:
        sensorVal = sens_D.read();
        break;
    }
#ifdef USB_DEBUG
    USB.print(F(" V:"));
    USB.println(sensorVal);
#endif
    return sensorVal;
  }
  else
  {
#ifdef USB_DEBUG
    USB.println(F("NO"));
#endif
  }
}


void setup()
{
  SWIonsBoard.ON();
  USB.ON();
  SD.ON();
  SD.create(filename);
  USB.println(F("Ready to work"));
  SD.appendln(filename,"Start logging data.");
}

void loop()
{
  if ( millis() - lastT > 10000 )
  {
    SWIonsBoard.ON();
    SD_write_Time();
    for ( int i = 1; i < 6; i++)
    {
      SD_write_part(sensName[i], getSensorData(i));
    }
    SD.appendln(filename, ".");
#ifdef USB_DEBUG
    USB.println(F("\n-----FILE CONTENTS----------"));
    SD.showFile(filename);
    USB.println(F("\n-----End_FILE---------------"));
#endif
    SWIonsBoard.OFF();
    lastT = millis();
  }
}
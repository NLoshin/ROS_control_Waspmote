#include <smartWaterIons.h>
#define USB_DEBUG 1
char buffer[255];
char fileIn[64];
char filename[] = "SWI_LOG.TXT";

#define USB_DEBUG 1
#define A_SENSOR 1
#define B_SENSOR 2
#define C_SENSOR 3
#define D_SENSOR 4
#define E_SENSOR 5
// Подключение
ionSensorClass sens[]{SOCKET_A,SOCKET_B,SOCKET_C,SOCKET_D,SOCKET_E};
//pt1000Class tempSensor;
char *sensName[] = {"TIME", "SENS_NO3", "SENS_NH4+", "SENS_NO2", "SENS_Cu2", "SENS_mdrx11"};
const uint8_t allSensorId[] = {A_SENSOR, B_SENSOR, C_SENSOR, D_SENSOR, E_SENSOR};
pt1000Class TemperatureSensor;
// Массивы точек калибровочной концентрации
const float calibs[][3] =
{
  {10.0,  100.0,  1000.0},
  {1.0,   2.0,    3.0},	// калибровочные точки для NO3
  {1.0,   2.0,    3.0},	// калибровочные точки для NH4+
  {1.0,   2.0,    3.0},	// калибровочные точки для NO2
  {1.0,   2.0,    3.0}	// калибровочные точки для Cu2
};
float sensVolt , sensCons;
float lastT = 0;
void SD_write_Time() {
  int TT[3];
  TT[2] = (millis() / 1000) % 60;
  TT[1] = (millis() / 60000) % 60;
  TT[0] = (millis() / 3600000);
  snprintf(buffer, sizeof(buffer), "(Time:%dh%dm%ds)", TT[0], TT[1], TT[2]);
  SD.append(filename, buffer);
  USB.print(buffer);
}
void SD_write_part(char _metk[], float _data = 0, float _data2 = 0) {
  char s1[16];
  char s2[16];
  dtostrf(_data, 3, 2, s1);
  dtostrf(_data2, 3, 2, s2);
  snprintf(buffer, sizeof(buffer), "(%s:%sv:%sppm/mg*L-1)", _metk, s1, s2);
  SD.append(filename, buffer);
  USB.print(buffer);
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

void setup()
{
  SWIonsBoard.ON();
  USB.ON();
  SD.ON();
  SD.create(filename);
  USB.println(F("Ready to work"));
  SD.appendln(filename,"...");
  SD.appendln(filename,"Start logging data.");
  for (int i = 1;i<5;i++)
    sens[i].setCalibrationPoints(calibs[i], calibs[0], 3); 
 
  //pHSensor.setpHCalibrationPoints(cal_point_10, cal_point_7, cal_point_4, cal_temperature);
}

void loop()
{
  //if ( millis() - lastT > 10000 )
  //{
    //SWIonsBoard.ON();
  float temperature = TemperatureSensor.read();
    SD_write_Time();
    for ( int i = 1; i < 6; i++)
    {
      sensVolt = sens[i].read();
      sensCons = sens[i].calculateConcentration(sensVolt);
      SD_write_part(sensName[i], sensVolt, sensCons );
    }
    SD.appendln(filename, ".");
  USB.println();
//#ifdef USB_DEBUG
    //USB.println(F("\n-----FILE CONTENTS----------"));
    //SD.showFile(filename);
    //USB.println(F("\n-----End_FILE---------------"));
//#endif
    //SWIonsBoard.OFF();
    //lastT = millis();
  //}
}

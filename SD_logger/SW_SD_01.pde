#include <WaspSensorSW.h>
#include <TurbiditySensor.h>
char buffer[255];
char fileIn[64];
char filename[] = "SW_LOG.TXT";
#define USB_DEBUG 1
#define DO_SENSOR 1
#define PH_SENSOR 2
#define TEMP_SENSOR 3
#define EC_SENSOR 4
#define TUR_SENSOR 5

char *sensName[] = {"TIME", "DO", "PH", "TEMP", "EC", "TUR"};
const  uint8_t allSensorId[] = {DO_SENSOR, PH_SENSOR, TEMP_SENSOR, EC_SENSOR, TUR_SENSOR};

DOClass DOSensor;// Датчик растворенного в воде кислорода
pHClass pHSensor;//Датчик pH
pt1000Class temperatureSensor;//Датчик температуры воды
conductivityClass ConductivitySensor;//Датчик электропроводимости
turbidityClass turbidity;//Датчик мутности

const int numChars = 90;
char recChars[numChars];
char commandPC[32] = {0};
int sensorId;
float param[4];
int newData = false;

long lastT = 0;
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

void readData() {
  static int readState = false;
  int ndx = 0;
  char rc;
  while (USB.available() > 0 && newData == false) {
    rc = USB.read();
    if (readState == true) {
      if (rc != '>') {
        recChars[ndx] = rc;
        ndx++;
        if (ndx >= numChars) ndx = numChars - 1;
      }
      else {
        readState = false;
        ndx = 0;
        newData = true;
      }
    } else if (rc == '<') readState = true;
  }
}

void parseData() {
  char * strtokIndx;
  strtokIndx = strtok(recChars, ",");
  strcpy(commandPC, strtokIndx);
  strtokIndx = strtok(NULL, ",");
  sensorId = atoi(strtokIndx);
  for (int ind = 0; ind < 4; ind++)
  {
    strtokIndx = strtok(NULL, ",");
    param[ind] = atof(strtokIndx);
  }
}

void showParsedData() {
  USB.printf("*************************************");
  USB.printf("Command: \t %d\n", commandPC);
  USB.printf("Sensor ID: \t %d\n", sensorId);
  for (int ind = 0; ind < 4; ind++)
    if ( param[ind] != 0)
      USB.printf("Parameter %d: \t %d\n", ind, param[ind]);
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

float getSensorData (uint8_t _sensorId, uint8_t typeOut = 0) {
  float sensorVal;
  float sensorVal_2;
#ifdef USB_DEBUG
  USB.printf("S: %d ", _sensorId);
#endif
  if ( chechId(_sensorId) )
  {
    switch ( _sensorId )
    {
      case DO_SENSOR:
        sensorVal = DOSensor.readDO();
        if ( typeOut != 0) sensorVal = DOSensor.DOConversion(sensorVal);
        break;
      case PH_SENSOR:
        sensorVal = pHSensor.readpH();
        if ( typeOut != 0)
        {
          float temp = temperatureSensor.readTemperature();
          sensorVal = pHSensor.pHConversion(sensorVal, temp);
        }
        break;
      case TEMP_SENSOR:
        sensorVal = temperatureSensor.readTemperature();
        break;
      case EC_SENSOR:
        sensorVal = ConductivitySensor.readConductivity();
        if ( typeOut != 0)
        {
          sensorVal = ConductivitySensor.conductivityConversion(sensorVal);
        }
        break;
      case TUR_SENSOR:
        sensorVal = turbidity.getTurbidity();
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

void setCalPoints (uint8_t sensorId, float _cal_point_01 = 0, float _cal_point_02 = 0, float _cal_point_03 = 0, float _cal_point_04 = 0) {
  float sensorVal;
  float sensorVal_2;
#ifdef USB_DEBUG
  USB.printf("Calibrating sensor %d ...", sensorId);
#endif
  if ( chechId(sensorId) && sensorId != 0)
  {
    switch ( sensorId )
    {
      case DO_SENSOR:
        DOSensor.setCalibrationPoints(_cal_point_01, _cal_point_02);
        break;
      case PH_SENSOR:
        pHSensor.setCalibrationPoints(_cal_point_01, _cal_point_02, _cal_point_03, _cal_point_04);
        break;
      case TEMP_SENSOR:
        sensorVal = temperatureSensor.readTemperature();
        break;
      case EC_SENSOR:
        ConductivitySensor.setCalibrationPoints(_cal_point_01, _cal_point_02, _cal_point_03, _cal_point_04);
        break;
    }
#ifdef USB_DEBUG
    USB.println(F("OK"));
#endif
  }
  else
  {
#ifdef USB_DEBUG
    USB.println(F("NO"));
#endif
  }
}

void analizData() {
  parseData();
  showParsedData();
  newData = false;
  if ( chechId(sensorId) )
  {
    if ( commandPC == "set")
      setCalPoints(sensorId, param[0], param[1], param[2], param[3]);
    else if ( commandPC == "get")
      getSensorData(sensorId);
    else if ( commandPC == "get")
      getSensorData(sensorId);
    else
    {
      USB.print(F("Not found command :"));
      USB.println(commandPC);
    }
  }
  else
  {
    USB.print(F("Not found sensor ID "));
    USB.println(sensorId);
  }
}

void setup() {
  USB.ON();
  SD.ON();
  //SD.del(filename);
  SD.create(filename);
  USB.println(F("Ready to work"));
  // Калибровка подключенных датчиков
  USB.println(F("Calibration..."));
  setCalPoints (DO_SENSOR, 2.65, 0);
  setCalPoints(PH_SENSOR, 1.985, 2.070, 2.227, 23.7);
  setCalPoints(EC_SENSOR, 10500, 40000, 197, 150);
  USB.println(F("OK"));
  turbidity.ON();
  Water.ON();
  SD.appendln(filename, "Start logging data.");
}

void loop() {
  if ( millis() - lastT > 10000 )
  {
    lastT = millis();
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
  }
  //if ( USB.available() ) readData();
  //if ( newData ) analizData();
}
#include <WaspSensorSW.h>

// Датчик растворенного в воде кислорода
#define DO_SENSOR 2
//Датчик pH
#define PH_SENSOR 3
//Датчик температуры воды
#define TEMP_SENSOR 4
//Датчик электропроводимости
#define EC_SENSOR 5
//Датчик мутности
#define TUR_SENSOR 6

#ifdef DO_SENSOR > 0
  #define air_calibration 2.65
  #define zero_calibration 0.0
  DOClass DOSensor;
#endif
#ifdef PH_SENSOR > 0
  #define cal_point_10  1.985
  #define cal_point_7   2.070
  #define cal_point_4   2.227
  #define cal_temp     23.7
  pHClass pHSensor;
  #define TEMP_SENSOR   99
#endif
#ifdef TEMP_SENSOR > 0
  pt1000Class temperatureSensor;
#endif
#ifdef EC_SENSOR > 0
  #define point1_cond 10500
  #define point2_cond 40000
  #define point1_cal 197.00
  #define point2_cal 150.00
  conductivityClass ConductivitySensor;
#endif
#ifdef TUR_SENSOR > 0
  #include <TurbiditySensor.h>
  turbidityClass turbidity;
#endif

uint8_t allSensorId[] = {DO_SENSOR,PH_SENSOR,TEMP_SENSOR,EC_SENSOR,TUR_SENSOR};

const int numChars = 90;
char recChars[numChars];
char commandPC[32] = {0};
int sensorId;
float param[4];
int newData = false;

void recData() {
  static int recInProgress = false;
  int ndx = 0;
  char rc;
  if (USB.available() > 0) {
    while (USB.available() > 0 && newData == false) {
      rc = USB.read();
      if (recInProgress == true) {
        if (rc != '>') {
          recChars[ndx] = rc;
          ndx++;
          if (ndx >= numChars) ndx = numChars - 1;
        }
        else {
          recInProgress = false;
          ndx = 0;
          newData = true;
        }
      }
      else if (rc == '<') recInProgress = true;
    }
  }
}

void parseData() {
  char * strtokIndx;
  strtokIndx = strtok(recChars,",");
  strcpy(commandPC, strtokIndx);
  strtokIndx = strtok(NULL, ",");
  sensorId = atoi(strtokIndx);
  for (int ind=0;ind<4;ind++)
  {
    strtokIndx = strtok(NULL, ",");
    param[ind] = atof(strtokIndx);
  }
}

void showParsedData() {
  USB.printf("*************************************");
  USB.printf("Command: \t %d\n", commandPC);
  USB.printf("Sensor ID: \t %d\n", sensorId);
  for (int ind=0;ind<4;ind++)
    if ( param[ind]!= 0)
      USB.printf("Parameter %d: \t %d\n",ind, param[ind]);
}

boolean chechId(uint8_t _sensorId) 
{
  boolean chechIdorId = false;
  for (int i=0; i<sizeof(allSensorId)/sizeof(uint8_t);i++)
  {
    if (_sensorId==allSensorId[i])
      chechIdorId = true;
  }
  return chechIdorId;
}

float getSensorData (uint8_t _sensorId, uint8_t typeOut=0) 
{
  float sensorVal;
  float sensorVal_2;
 
  if ( chechId(_sensorId) )
  {
    switch ( _sensorId )
    {
      
      #ifdef DO_SENSOR > 0
        case DO_SENSOR:
          sensorVal = DOSensor.readDO();
          if ( typeOut != 0) sensorVal = DOSensor.DOConversion(sensorVal);
          break;
      #endif

      #ifdef PH_SENSOR > 0
        case PH_SENSOR:
          sensorVal = pHSensor.readpH();
          if ( typeOut != 0)
          { 
            float temp = temperatureSensor.readTemperature();
            sensorVal = pHSensor.pHConversion(sensorVal, temp);
          }
          break;
      #endif

      #ifdef TEMP_SENSOR > 0
        case TEMP_SENSOR:
          sensorVal = temperatureSensor.readTemperature();
          break;
      #endif
      
      #ifdef EC_SENSOR > 0
        case EC_SENSOR:
          sensorVal = ConductivitySensor.readConductivity();
          if ( typeOut != 0)
          { 
            sensorVal = ConductivitySensor.conductivityConversion(sensorVal);
          }
          break;
      #endif
      
      #ifdef TUR_SENSOR > 0
        case TUR_SENSOR:
          sensorVal = turbidity.getTurbidity();
          break;
      #endif
    }
    USB.print(F("S: "));
    USB.println(sensorId);
    USB.print(F("V:"));
    USB.println(sensorVal);
  }
  else
  {
    USB.print(F("S: "));
    USB.print(sensorId);
    USB.println(F("NO"));
  }
}
void setCalPoints (uint8_t sensorId,float _cal_point_01=0,float _cal_point_02=0,float _cal_point_03=0,float _cal_point_04=0)
{
  float sensorVal;
  float sensorVal_2;
  if ( chechId(sensorId) )
  {
    switch ( sensorId )
    {
      #ifdef DO_SENSOR > 0
        case DO_SENSOR:
          DOSensor.setCalibrationPoints(_cal_point_01,_cal_point_02);
          break;
      #endif
      #ifdef PH_SENSOR > 0
        case PH_SENSOR:
          pHSensor.setCalibrationPoints(_cal_point_01,_cal_point_02,_cal_point_03,_cal_point_04); 
          break;
      #endif
      #ifdef TEMP_SENSOR > 0
        case TEMP_SENSOR:
          sensorVal = temperatureSensor.readTemperature();
          break;
      #endif
      #ifdef EC_SENSOR > 0
        case EC_SENSOR:
          ConductivitySensor.setCalibrationPoints(_cal_point_01,_cal_point_02,_cal_point_03,_cal_point_04);
          break;
      #endif
    }
    USB.printf("Sensor ID %d set OK",sensorId);
  }
  else
  {
    USB.printf("Sensor ID %d  no set",sensorId);
  }
}

void setup()
{
  USB.ON();
  USB.println(F("Ready to work"));
  // Калибровка подключенных датчиков
  #ifdef DO_SENSOR > 0
    setCalPoints (DO_SENSOR,air_calibration, zero_calibration);
  #endif
  #ifdef PH_SENSOR > 0
    setCalPoints(PH_SENSOR,cal_point_10, cal_point_7, cal_point_4, cal_temp);
  #endif
  #ifdef EC_SENSOR > 0
    setCalPoints(EC_SENSOR,point1_cond, point1_cal, point2_cond, point2_cal);
  #endif
  #ifdef TUR_SENSOR > 0
    turbidity.ON();
  #endif
  Water.ON(); 
}

void loop()
{
  recData();
  if (newData == true) {
    parseData();
    showParsedData();
    newData = false;
    if ( chechId(sensorId) )
    {
      if ( commandPC == "set")
        setCalPoints(sensorId,param[0],param[1],param[2],param[3]);
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
}

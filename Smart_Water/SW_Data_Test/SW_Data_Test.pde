#include <WaspSensorSW.h>

// Датчик растворенного в воде кислорода
#define DO_SENSOR 1
//Датчик pH
#define PH_SENSOR 2
//Датчик температуры воды
#define TEMP_SENSOR 3
//Датчик электропроводимости
#define EC_SENSOR 4
//Датчик мутности
#define TUR_SENSOR 5

#ifdef DO_SENSOR > 0
  DOClass DOSensor;
#endif
#ifdef PH_SENSOR > 0
  pHClass pHSensor;
  #define TEMP_SENSOR   99
#endif
#ifdef TEMP_SENSOR > 0
  pt1000Class temperatureSensor;
#endif
#ifdef EC_SENSOR > 0
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

boolean chechId(uint8_t _sensorId) {
  boolean chechIdorId = false;
  for (int i=0; i<sizeof(allSensorId)/sizeof(uint8_t);i++)
  {
    if (_sensorId==allSensorId[i])
      chechIdorId = true;
  }
  return chechIdorId;
}

float getSensorData (uint8_t _sensorId, uint8_t typeOut=0) {
  float sensorVal;
  float sensorVal_2;
  USB.printf("S: %d ",_sensorId);
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
    USB.print(F(" V:"));
    USB.println(sensorVal);
  }
  else
  {
    USB.println(F("NO"));
  }
}

void setCalPoints (uint8_t sensorId,float _cal_point_01=0,float _cal_point_02=0,float _cal_point_03=0,float _cal_point_04=0) {
  float sensorVal;
  float sensorVal_2;
  
  USB.printf("Calibrating sensor %d ...",sensorId);
  if ( chechId(sensorId) && sensorId != 0)
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
    USB.println(F("OK"));
  }
  else
  {
    USB.println(F("NO"));
  }
}

void analizData() {
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

void setup() {
  USB.ON();
  USB.println(F("Ready to work"));
  // Калибровка подключенных датчиков
  USB.println(F("Calibration..."));
  setCalPoints (DO_SENSOR,2.65,0);
  setCalPoints(PH_SENSOR,1.985,2.070,2.227,23.7);
  setCalPoints(EC_SENSOR,10500,40000,197,150);
  USB.println(F("OK"));
  turbidity.ON();
  Water.ON(); 
}
void loop() {
  if ( millis()-lastT > 10000 )
  {
	for ( int i = 1; i<6; i++)
	{
	  getSensorData(i);
	}
	lastT = millis();
  }
  if ( USB.available() ) readData();
  if ( newData ) analizData();
}
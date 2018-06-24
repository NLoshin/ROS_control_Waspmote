#include <WaspSensorSW.h>

float pHVol;
float temp;
float pHValue;

// Calibration values
#define cal_point_10  1.985
#define cal_point_7   2.070
#define cal_point_4   2.227

// Temperature at which calibration was carried out
#define cal_temp 23.7

pHClass pHSensor;
pt1000Class temperatureSensor;


void setup()
{
  USB.ON();
  USB.println(F("pH example for Smart Water..."));
  
  // Store the calibration values 
  pHSensor.setCalibrationPoints(cal_point_10, cal_point_7, cal_point_4, cal_temp);

  ///////////////////////////////////////////
  // 1. Turn ON the Smart Water sensor board 
  ///////////////////////////////////////////  
  Water.ON(); 
}


void loop()
{
  ///////////////////////////////////////////
  // 2. read the sensors
  ///////////////////////////////////////////   
  
  // Read the ph sensor (voltage value)
  pHVol = pHSensor.readpH();
  // Read the temperature sensor
  temp = temperatureSensor.readTemperature();
  // Convert the value read with the information obtained in calibration
  pHValue = pHSensor.pHConversion(pHVol, temp);
 
  ///////////////////////////////////////////
  // 3. Print the output values
  ///////////////////////////////////////////
  
  USB.print(F("pH value: "));
  USB.print(pHVol);
  USB.print(F("volts  | "));
  USB.print(F(" Temperature: "));
  USB.print(temp);
  USB.print(F("degrees  | "));  
  USB.print(F(" pH Estimated: "));
  USB.println(pHValue);


}


#include <smartWaterIons.h>
// Подключение
ionSensorClass calciumSensor(SOCKET_A);
ionSensorClass NO3Sensor(SOCKET_B);
ionSensorClass pHSensor(SOCKET_C);
ionSensorClass fluorideSensor(SOCKET_D);
pt1000Class tempSensor;
// Точки калибровочной концентрации
#define point1 10.0
#define point2 100.0
#define point3 1000.0
// Значения калибровочного напряжения для датчика кальция
#define point1_volt_Ca 2.163
#define point2_volt_Ca 2.296
#define point3_volt_Ca 2.425
// Значения калибровочного напряжения для датчика NO3
#define point1_volt_NO3 3.080
#define point2_volt_NO3 2.900
#define point3_volt_NO3 2.671
// Значения калибровочного напряжения для датчика фторида
#define point1_volt_F 3.115
#define point2_volt_F 2.834
#define point3_volt_F 2.557
// Калибровочные значения для датчика pH
#define cal_point_10 1.405
#define cal_point_7  2.048
#define cal_point_4 2.687
#define cal_temperature 22.0
// Количество калибровочных точек
#define NUM_POINTS 3
const float concentrations[] = {point1, point2, point3 };
const float voltages_Ca[] = {point1_volt_Ca, point2_volt_Ca, point3_volt_Ca}; 
const float voltages_NO3[] = {point1_volt_NO3, point2_volt_NO3, point3_volt_NO3 }; 
const float voltages_F[] = { point1_volt_F, point2_volt_F, point3_volt_F }; 
//======================================================================
void setup()
{
  SWIonsBoard.ON();
  USB.ON();  
  // Калибровка датчика кальция
  calciumSensor.setCalibrationPoints(voltages_Ca, concentrations, NUM_POINTS); 
  // Калибровка датчика NO3
  NO3Sensor.setCalibrationPoints(voltages_NO3, concentrations, NUM_POINTS);  
  // Калибровка датчика фторида
  fluorideSensor.setCalibrationPoints(voltages_F, concentrations, NUM_POINTS);  
  // Калибровка датчика pH
  pHSensor.setpHCalibrationPoints(cal_point_10, cal_point_7, cal_point_4, cal_temperature);
}

void loop()
{
  if ( millis()-lastT > 10000 )
  {
    SWIonsBoard.ON();
    float CaVolts = calciumSensor.read();
    float calciumValue = calciumSensor.calculateConcentration(CaVolts);
    delay(50);
    USB.print(F(" Calcium : "));
    USB.print(calciumValue);
    float NO3Volts = NO3Sensor.read();
    float NO3Value = NO3Sensor.calculateConcentration(NO3Volts);
    delay(50);
    USB.print(F(" | NO3: "));
    USB.print(NO3Value);
    float flourVolts = fluorideSensor.read();
    float flourideValue = fluorideSensor.calculateConcentration(flourVolts);
    delay(50);
    USB.print(F(" | Fluoride: "));
    USB.print(flourideValue);
    float tempValue = tempSensor.read();
    delay(50);
    USB.print(F(" | Temp: "));
    USB.print(tempValue);
    //===============Read the pH sensor=========================
    float pHVolts = pHSensor.read();
    float pHValue = pHSensor.pHConversion(pHVolts, tempValue);
    delay(50);
    USB.print(F(" | pH: "));
    USB.print(pHValue);
    USB.print(F(">\n"));
    SWIonsBoard.OFF();
	  lastT = millis();
  }
}

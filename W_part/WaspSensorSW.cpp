#include "WaspSensorSW.h"

#ifndef __WPROGRAM_H__
  #include <WaspClasses.h>
#endif

//**************************************************************************************************
// Smart Water Class
//**************************************************************************************************
WaspSensorSW::WaspSensorSW()
{
	WaspRegisterSensor |= REG_WATER;
}
void WaspSensorSW::ON(void)
{
	pinMode(DIGITAL8, OUTPUT);	// pH sensor control pin
	pinMode(ANA1, OUTPUT);		// ORP sensor control pin
	pinMode(ANA2, OUTPUT);		// DO sensor control pin
	pinMode(ANA3, OUTPUT);		// DI  sensor control pin
	pinMode(DIGITAL7, OUTPUT);	// Conductivity sensor control pin
	digitalWrite(DIGITAL8, LOW);
	digitalWrite(ANA1, LOW);
	digitalWrite(ANA2, LOW);
	digitalWrite(ANA3, LOW);
	digitalWrite(DIGITAL7, LOW);
	
	PWR.setSensorPower(SENS_5V, SENS_ON);	// Turn on the power switches in Waspmote
	PWR.setSensorPower(SENS_3V3, SENS_ON);
	delay(10);
	myADC.begin();		// Configure the ADC
	
	#if DEBUG_WATER > 1
		PRINTLN_WATER(F("Smart Water Sensor Board Switched ON"));
	#endif
}
void WaspSensorSW::OFF(void)
{
	PWR.setSensorPower(SENS_5V, SENS_OFF);
	PWR.setSensorPower(SENS_3V3, SENS_OFF);
	
	#if DEBUG_WATER > 1
		PRINTLN_WATER(F("Smart Water Sensor Board Switched OFF"));
	#endif
}

//!*************************************************************************************
//!	Name:	getMeasure()										
//!	Description: Get some measures from the ADC 
//!	Param : 	uint8_t adcChannel: the channel of the ADC to read
//!				uint8_t digitalPin: digital pin to switch ON the corresponding circuit
//!	Returns:	flaot: the volatge read from the ADC							
//!*************************************************************************************
float WaspSensorSW::getMeasure(uint8_t adcChannel, uint8_t digitalPin)
{
	digitalWrite(digitalPin, HIGH); 	//Switch ON the corresponding sensor circuit
	delay(100);
	float value_array[FILTER_SAMPLES];

	// Take some measurements to filter the signal noise and glitches
	for(int i = 0; i < FILTER_SAMPLES; i++)
	{
		value_array[i] = myADC.readADC(adcChannel); 	//Read from the ADC channel selected
	}
	//Switch OFF the corresponding sensor circuit
	digitalWrite(digitalPin, LOW);
	delay(100);
	return myFilter.median(value_array,FILTER_SAMPLES);
}
pt1000Class::pt1000Class(){}
float pt1000Class::readTemperature(void)
{
	float value;
	float val;
	float vals[FILTER_SAMPLES];
	// Take some measurements to filter the signal noise and glitches
	for(int i = 0; i < FILTER_SAMPLES; i++)
	{
		// Read ADC to acquire the output voltage
		value = myADC.readADC(TEMP_CHANNEL);
		
		// Convert the voltage value into a temperature
		// (5 + (5* 82 / 68))  = Gain of the instrumentation amplifier (In datasheet)
		val = value / (5 + 5 * 82 / 68 );
		
		// 												(2,048 + Vadc) * R(1k)
		// The complete formula =>			Rout = 	============================   
		//												(4,096 - 2,048 - Vadc)
		// 2,048 = The referencia for the amplifier
		// 4,096 = The supply of the sensor
		// R(1K) = A 1K resistor is used in a resistance divisor
		// Vadc = The voltage measured by the ADC
		//															  |\
		//							Vo -------------------------------| \
		//							|								 _|  |----- VAdc
		//   4,096 -> |----/\/\/\--------/\/\/\----| Ground			| | /
		//					1k			Pt1000						| |/
		//															2,048 (Reference)
		//
		val = (val + 2.048) / (2.048 - val) * 1000;

		// This formula can be extracted (aproximately) by linearizing with two points
		// (x1 , y1) = (0ºC,  1000 Ohm)
		// (x2 , y2) = (79ºC, 1300 Ohm)
		val = 0.26048 * val - 260.83;
		vals[i] = val;
		
		// Wait for 10 milliseconds for the next reading
		delay(10);
	}

	// Calculate the median value of the fifteen readings
	return  myFilter.median(vals, FILTER_SAMPLES);
}


pHClass::pHClass()
{
	pHChannel = PH_CHANNEL;
	pHSwitch = DIGITAL8;
}

pHClass::pHClass(uint8_t channel)
{
	// The pH sensor can be used in the DI and in the ORP sockets
	if ((channel == ORP_SOCKET) || (channel == SOCKET_E))
	{
		// Configuring the pH sensor to be used in the ORP socket
		pHChannel = ORP_CHANNEL;
		pHSwitch = ANA1;
		
	} else
	{
		// Else, default configuration
		pHChannel = PH_CHANNEL;
		pHSwitch = DIGITAL8;
	}
}

float pHClass::readpH()
{
	#if DEBUG_WATER > 1
		if (pHChannel == PH_CHANNEL) 
		{
			PRINTLN_WATER(F("Reading pH sensor in default SOCKET (Plug&Sense -> SOCKETA)"));
		}
		else 
		{
			PRINTLN_WATER(F("Reading pH sensor from ORP SOCKET (Plug&Sense -> SOCKETD)"));
		}
	#endif
	
	return Water.getMeasure(pHChannel, pHSwitch);
}

float pHClass::pHConversion(float input)
{
	return pHConversion(input, 0);
}

float pHClass::pHConversion(float input, float temp)
{
	float sensitivity;
	if( (temp < 0)||(temp > 100))	return -1.0;
	if((calibration_temperature < 0)||(calibration_temperature > 100))	return -2.0;

	// TWo ranges calibration
	if (input > calibration_point_7 ) {
		// The sensitivity is calculated using the other two calibration values
		// Asumme that the pH sensor is lineal in the range.
		// sensitivity = pHVariation / volts
		// Divide by 3 = (pH) 7 -  (pH) 4
		sensitivity = (calibration_point_4-calibration_point_7)/3;
		// Add the change in the pH owed to the change in temperature
		sensitivity = sensitivity + (temp - calibration_temperature)*0.0001984;

		// The value at pH 7.0 is taken as reference		
		// => Units balance => 7 (pH) + (volts) / ((pH) / (volts)) 
		return 7.0 + (calibration_point_7-input) / sensitivity;
		//				|					|
		//			(pH 7 voltage	-	Measured volts) = Variation from the reference 
	} else	{
		// The sensitivity is calculated using the other two calibration values
		sensitivity = (calibration_point_7-calibration_point_10) / 3;
		// Add the change in the pH owed to the change in temperature
		sensitivity = sensitivity + (temp - calibration_temperature)*0.0001984;

		return 7.0 + (calibration_point_7-input)/sensitivity;
	}
}

void pHClass::setCalibrationPoints(float _calibration_point_10,
				   float _calibration_point_7,
				   float _calibration_point_4,
				   float _calibration_temperature)
{
	calibration_point_10 = _calibration_point_10;
	calibration_point_7 = _calibration_point_7;
	calibration_point_4 = _calibration_point_4;
	calibration_temperature = _calibration_temperature;
}
conductivityClass::conductivityClass(){}
float conductivityClass::readConductivity(void)
{
	return resistanceConversion(Water.getMeasure(COND_CHANNEL, DIGITAL7));
}
float conductivityClass::conductivityConversion(float input)
{
	float value;
	float SW_condK;
	float SW_condOffset;
	// Calculates the cell factor of the conductivity sensor and the offset from the calibration values
	SW_condK = point_1_cond * point_2_cond * ((point_1_cal-point_2_cal)/(point_2_cond-point_1_cond));
	SW_condOffset = (point_1_cond * point_1_cal-point_2_cond*point_2_cal)/(point_2_cond-point_1_cond);
	// Converts the resistance of the sensor into a conductivity value
	value = SW_condK * 1 / (input+SW_condOffset);
	return value;
}
void conductivityClass::setCalibrationPoints(float _point_1_cond, float _point_1_cal,
					     float _point_2_cond, float _point_2_cal)
{
		point_1_cond = _point_1_cond;
		point_1_cal = _point_1_cal;
		point_2_cond = _point_2_cond;
		point_2_cal = _point_2_cal;
}
 float conductivityClass::resistanceConversion(float input)
{  
	float value;

	input = input / 2.64;

	// These values have been obtained experimentaly
	if(input<=SW_COND_CAL_01)
	value = 0;
	
	else if(input<SW_COND_CAL_02)
		value = 100 * (input-SW_COND_CAL_01)/(SW_COND_CAL_02-SW_COND_CAL_01);
		
	else if(input<SW_COND_CAL_03)
		value = 100 + 120 * (input-SW_COND_CAL_02)/(SW_COND_CAL_03-SW_COND_CAL_02);
		
	else if(input<SW_COND_CAL_04)
		value = 220 + 220 * (input-SW_COND_CAL_03)/(SW_COND_CAL_04-SW_COND_CAL_03);
		
	else if(input<SW_COND_CAL_05)
		value = 440 + 560 * (input-SW_COND_CAL_04)/(SW_COND_CAL_05-SW_COND_CAL_04);
		
	else if(input<SW_COND_CAL_06)
		value = 1000 + 1200 * (input-SW_COND_CAL_05)/(SW_COND_CAL_06-SW_COND_CAL_05);
		
	else if(input<SW_COND_CAL_07)
		value = 2200 + 2200 * (input-SW_COND_CAL_06)/(SW_COND_CAL_07-SW_COND_CAL_06);
		
	else if(input<SW_COND_CAL_08)
		value = 4400 + 1200 * (input-SW_COND_CAL_07)/(SW_COND_CAL_08-SW_COND_CAL_07);
		
	else if(input<SW_COND_CAL_09)
		value = 5600 + 4400 * (input-SW_COND_CAL_08)/(SW_COND_CAL_09-SW_COND_CAL_08);

	else if(input<SW_COND_CAL_10)
		value = 10000 + 5000 * (input-SW_COND_CAL_09)/(SW_COND_CAL_10-SW_COND_CAL_09);
		
	else if(input<SW_COND_CAL_11)
		value = 15000 + 7000 *(input-SW_COND_CAL_10)/(SW_COND_CAL_11-SW_COND_CAL_10);
	
	else if(input<SW_COND_CAL_12)
		value = 22000 + 11000 * (input-SW_COND_CAL_11)/(SW_COND_CAL_12-SW_COND_CAL_11);
	
	else if(input<SW_COND_CAL_13)
		value = 33000 + 14000 * (input-SW_COND_CAL_12)/(SW_COND_CAL_13-SW_COND_CAL_12);
	
	else if(input<SW_COND_CAL_14)
		value = 47000 + 21000 *(input-SW_COND_CAL_13)/(SW_COND_CAL_14-SW_COND_CAL_13);
	
	else if(input<SW_COND_CAL_15)
		value = 68000 + 32000 * (input-SW_COND_CAL_14)/(SW_COND_CAL_15-SW_COND_CAL_14);
	
	else
		value = 100000+900000*(input-SW_COND_CAL_15)/(SW_COND_CAL_16-SW_COND_CAL_15);

	return value;
}

ORPClass::ORPClass()
{
	ORPChannel = ORP_CHANNEL;
	ORPSwitch = ANA1;
}

ORPClass::ORPClass(uint8_t channel)
{
	// The ORP sensor can be used in the DI and in the pH sockets
	if ((channel == pH_SOCKET) || (channel == SOCKET_A))
	{
		// Configuring the ORP sensor to be used in the pH socket
		ORPChannel = PH_CHANNEL;
		ORPSwitch = DIGITAL8;
	} 
	else
	{
		// Else, default configuration
		ORPChannel = ORP_CHANNEL;
		ORPSwitch = ANA1;
	}
}

float ORPClass::readORP()
{
	#if DEBUG_WATER > 1
		if (ORPChannel == ORP_CHANNEL) 
		{
			PRINTLN_WATER(F("Reading ORP sensor in default SOCKET (Plug&Sense -> SOCKETD)"));
		}
		else 
		{
			PRINTLN_WATER(F("Reading ORP sensor from pH SOCKET (Plug&Sense -> SOCKETA)"));
		}
	#endif
	
	return Water.getMeasure(ORPChannel, ORPSwitch) - 2.048;
}

//**************************************************************************************************
// Dissolved Oxygen Sensor Class
//**************************************************************************************************
//!*************************************************************************************
//!	Name:	readDO()
//!	Description: read the value of the DO sensor
//!	Param: void
//!	Returns: 	float: DO  value of the sensor
//!*************************************************************************************
float DOClass::readDO()
{
	return Water.getMeasure(DO_CHANNEL, ANA2);
}

//!*************************************************************************************
//!	Name:	readDO()
//!	Description: Configure teh calibration parameters of the DO sensor
//!	Param: float air_value  : sensor voltage in air
//!			float zero_value : sensor voltage in zero oxygen solution
//!	Returns: void
//!*************************************************************************************
void DOClass::setCalibrationPoints(float _air_calibration, float _zero_calibration)
{
	air_calibration  = _air_calibration; 
	zero_calibration = _zero_calibration;
}

//!*************************************************************************************
//!	Name:	DOConversion()
//!	Description: Converts the DO voltage into a percentage of concentration
//!	Param: float input 	 : voltage measured
//!	Returns: 	float value : the dissolved oxygen concentration of the solution
//!*************************************************************************************
float DOClass::DOConversion(float input)
{	
	// Calculates the concentration of dissolved oxygen
	return (input - zero_calibration)/(air_calibration - zero_calibration) * 100;
}



//**************************************************************************************************
// Dissolved Ions Class
//**************************************************************************************************
//!*************************************************************************************
//!	Name:	DIClass()										
//!	Description: Class contructor		
//!	Param : channel of the ADC to configure								
//!	Returns: void							
//!*************************************************************************************
DIClass::DIClass()
{
	DIChannel = DI_CHANNEL;
	DISwitch = ANA3;
}

//!*************************************************************************************
//!	Name:	DIClass()
//!	Description: Class contructor
//!	Param : channel of the ADC to configure
//!	Returns: void
//!*************************************************************************************
DIClass::DIClass(uint8_t channel)
{
	// The DI sensor can be used in the ORP and in the pH sockets
	if ((channel == ORP_SOCKET) || (channel == pH_SOCKET))
	{
		if (channel == ORP_SOCKET)
		{
			// Configuring the DI sensor to be used in the ORP socket
			DIChannel = ORP_CHANNEL;
			DISwitch = ANA1;
		}
		else
		{
			// Configuring the DI sensor to be used in the pH socket
			DIChannel = PH_CHANNEL;
			DISwitch = DIGITAL8;
		}
	} else
	{
		// Else, default configuration
		DIChannel = DI_CHANNEL;
		DISwitch = ANA3;
	}
}
float DIClass::readDI()
{
	return Water.getMeasure(DIChannel, DISwitch);
}
void DIClass::setCalibrationPoints(float calibrationValues[])
{
	// This function is no neccesary. The next function (below) is more general.
	
	// The calibration process use a Non-Lineal Calibration process
	// The process uses 3-points to calibrate the sensor
	// The complete process is decribed in the next link: 
	// http://es.wikipedia.org/wiki/Regresi%C3%B3n_no_lineal

	// The sensor has a logarithmic response: 
	// y = a * log10(x) + b; y(volts), x(ppm) 
	// x(ppm) = 10 exp ((y-b)/a)
	// a = slope of the logarithmic function
	// b = intersection of the logarithmic function

	// The next variables are neccesary to calculate the slope and the intersection

	// Summation of the voltages (y values) 
	float SUMy = calibrationValues[3] + calibrationValues[4] + calibrationValues[5];
	// y values average
	float SUMy_avg = SUMy / 3; 
	// Summation of the logarithm of the x values
	float SUMLogx = log10(calibrationValues[0]) + log10(calibrationValues[1]) + log10(calibrationValues[2]);
	// Summation of the logarithm of the x values
	float SUMLogx_2 = 	log10(calibrationValues[0])*log10(calibrationValues[0]) + 
						log10(calibrationValues[1])*log10(calibrationValues[1]) + 
						log10(calibrationValues[2])*log10(calibrationValues[2]); 

	float SUMLogx_y = 	log10(calibrationValues[0])* calibrationValues[3]+ 
						log10(calibrationValues[1])* calibrationValues[4]+ 
						log10(calibrationValues[2])* calibrationValues[5];
	// Sum of the square of the logarithm of the x values
	float SUMLogx_avg = SUMLogx / 3;
	// Slope of the logarithmic function 
	slope = (SUMLogx_y - SUMy_avg * SUMLogx) / (SUMLogx_2 - SUMLogx_avg * SUMLogx);  
	// Intersection of the logarithmic function
	intersection = SUMy_avg - (slope * SUMLogx_avg);
	#if DEBUG_WATER >1
		PRINT_WATER(F("Slope: ")); 
		PRINT_WATER_VAL(slope);

		PRINT_WATER(" | Intersection: "); 
		PRINTLN_WATER_VAL(intersection);
	#endif
}
void DIClass::setCalibrationPoints(float calVoltages[], float calConcentrations[],  uint8_t numPoints)
{
	// The calibration process use a Non-Lineal Calibration process
	// The process uses 3-points to calibrate the sensor
	// The complete process is decribed in the next link: 
	// http://es.wikipedia.org/wiki/Regresi%C3%B3n_no_lineal
	
	// The sensor has a logarithmic response: 
	// y = a * log10(x) + b; y(volts), x(ppm) 
	// x(ppm) = 10 exp ((y-b)/a)
	// a = slope of the logarithmic function
	// b = intersection of the logarithmic function
	
	// The next variables are neccesary to calculate the slope and the intersection
	
	// Summation of the voltages (y values)
	float SUMy = 0.0;

	for (int i = 0; i < numPoints; i++) {
		SUMy = SUMy + calVoltages[i];
	}
	// y values average
	float SUMy_avg = SUMy / numPoints; 
	// Summation of the logarithm of the x values
	float SUMLogx = 0.0;

	for (int i = 0; i < numPoints; i++) { 
		SUMLogx	= SUMLogx + log10(calConcentrations[i]);
	}
	
	// Sum of the square of the logarithm of the x values
	float SUMLogx_2 = 0.0;

	for (int i = 0; i < numPoints; i++) {
		SUMLogx_2 = SUMLogx_2 + log10(calConcentrations[i])*log10(calConcentrations[i]);
	}
	// Sumation of the logx * y
	float SUMLogx_y = 0.0;
	for (int i = 0; i < numPoints; i++) {
		SUMLogx_y = SUMLogx_y + log10(calConcentrations[i])* calVoltages[i];
	}
	// Average of the log x values
	float SUMLogx_avg = SUMLogx / numPoints;
	// Slope of the logarithmic function 
	slope = (SUMLogx_y - SUMy_avg * SUMLogx) / (SUMLogx_2 - SUMLogx_avg * SUMLogx);
	// Intersection of the logarithmic function
	intersection = SUMy_avg - (slope * SUMLogx_avg);
	#if DEBUG_WATER > 1
		PRINT_WATER(F("Slope: ")); 
		PRINT_WATER_VAL(slope);

		PRINT_WATER(" | Intersection: "); 
		PRINTLN_WATER_VAL(intersection);
	#endif
}
float DIClass::calculateConcentration(float input)
{
	// y = a * log10(x) + b => x = 10 ^ ((y - b) / a)
	return  pow(10, ((input - intersection) / slope));
}
WaspSensorSW Water = WaspSensorSW();

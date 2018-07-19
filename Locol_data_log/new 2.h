/* sprintf example */
#include <stdio.h>

int main ()
{
  char buffer [50];
  int n, a=5, b=3;
  n=sprintf (buffer, "%d plus %d is %d", a, b, a+b);
  printf ("[%s] is a string %d chars long\n",buffer,n);
  return 0
}
char buffer[255];  // make sure this is big enough!!!
snprintf(buffer, sizeof(buffer), "(%g, %g)", c1, c2);
storedCorrect[count] = buffer;vxcz
ZCXVcz
ZCXVczZCXVcz
  // прочитать три датчика и добавить данные к строке:
  for (int analogPin = 0; analogPin < 3; analogPin++) 
  {
    int sensor = analogRead(analogPin);
    dataString += String(sensor);
    if (analogPin < 2) 
    {
      dataString += ",";
    }
  }
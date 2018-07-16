const int numChars = 90;
char readChars[numChars];
char toPC[32] = {0};
char fromPC[32] = {0};
int newData = false;

void readData() {
  if (Serial.available() > 0) {
    static int readState = false;
    int ind = 0;
    char readB;
    while (Serial.available() > 0 && newData == false) 
    {
      readB = Serial.read();
      if ( readState ) 
      {
        if (readB != '>') 
        {
          fromPC[ind] = readB;
          ind++;
        }
        else 
        {
          readState = false;
          ind = 0;
          newData = true;
        }
      }
      else if (readB == '<') readState = true;
    }
  }
}

void parseData() {
  char * strtokIndx;
  strtokIndx = strtok(fromPC,":");
  strcpy(commandPC, strtokIndx);
  strtokIndx = strtok(NULL, ":");
  sensorId = atoi(strtokIndx);
  for (int ind=0;ind<4;ind++)
  {
    strtokIndx = strtok(NULL, ",");
    param[ind] = atof(strtokIndx);
  }
}

void setup() {
  Serial.begin(115200);
}

void loop() {
  readData(); 
}

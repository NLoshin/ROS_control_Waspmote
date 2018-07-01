const byte numChars = 90;
char recChars[numChars];

char commandPC[32] = {0};
int sensorId;
float param[4];

boolean newData = false;



void recvWithStartEndMarkers() {
  static boolean recInProgress = false;
  static byte ndx = 0;
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
          //recChars[ndx] = '\0'; // terminate the string
          recInProgress = false;
          ndx = 0;
          newData = true;
        }
      }
      else if (rc == '<') {
        recInProgress = true;
      }
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
  USB.println(F("*************************************"));
  USB.printf("Command: \t %d\n", commandPC);
  USB.printf("Sensor ID: \t %d\n", sensorId);
  for (int ind=0;ind<4;ind++)
    if ( param[ind]!= 0)
      USB.printf("Parameter %d: \t %d\n",ind, param[ind]);
}



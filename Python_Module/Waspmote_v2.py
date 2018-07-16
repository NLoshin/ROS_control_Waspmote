import serial
import atexit
import datetime
import time

debug = True
global com

class Waspmote:
	def __init__(self, port, baudrate=115200):
		self.port = port
        self.baudrate = baudrate
		self.stopState = False
		try: 
			self.com = serial.Serial(self.port, self.baudrate, timeout=0.25)
			time.sleep(1)
			stopState2 = False
		except: print ('Could not connect at port %s.' % port)
		if debug: print ('Serial connection at port %s.' % port)
		atexit.register(self.disconnect)

	def read(self):
		result = self.com.readline()
		#print(data) #strip out the new lines for now
		strok = result.decode('utf-8')[1:-3]
		#print(strok) #strip out the new lines for now
		if debug: print(result)
		result = strok.split(':')
		if result:
			return result
		else:
			return None

	def write(self, _id, _comm, _param):
		self.com.write('<%s:%s:%s>\r\n' % (_id, _comm, _param))
		if debug: print('<%s:%s:%s>\r\n' % (_id, _comm, _param))

	def disconnect(self):
		if self.com: self.com.close()
		if debug: print('Serial connection closed')

	def printToFile(_filename='dataFile.txt',_sensorId,_data=0):
		dataFile = open(_filename, 'a')
		if ( _sensorId == 0):
			dataFile.write('Time:')
			dataFile.write(datetime.datetime.now().strftime("%d.%m.%Y-%H.%M.%S"))
		else:
			dataFile.write('|S:')
			dataFile.write(_sensorId)
			dataFile.write('-V:')
			dataFile.write(_data)
			dataFile.write('\n')
			dataFile.close()

if __name__ == "__main__":
	wasp0 = Waspmote('COM18', 115200)
	while( not wasp0.stopState):
		userInput = input('Command: ').split(':') #<'ID':'COMMAND':'REZULT'>
		if (userInput[0] == 'get'):
			data = getValues(userInput[1])
			printToFile(userInput[1],data)
			dataInt = int(data)
			dataList[0] = dataInt
			print(dataList)
		if (userInput[0] == 'n'):
			wasp0.stopState = True
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

	def readData(self):
		result = self.com.readline()
		strok = result.decode('utf-8')[1:-3]
		#print(strok) #strip out the new lines for now
		#result = strok.split(':')
		if strok:
			dataFile = open('dataFile.txt', 'a')
			dataFile.write('Time:')
			print(datetime.datetime.now().strftime("%d.%m.%Y-%H.%M.%S"))
			dataFile.write(datetime.datetime.now().strftime("%d.%m.%Y-%H.%M.%S"))
			print(strok)
			dataFile.write(strok)
			dataFile.write('\n')
			dataFile.close() 
		else:
			return None

	def disconnect(self):
		if self.com: self.com.close()
		if debug: print('Serial connection closed')


if __name__ == "__main__":
	wasp0 = Waspmote('/dev/ttyS0', 115200) //'COM17'
	while( not wasp0.stopState):
		wasp0.readData()
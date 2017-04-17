//
//  SerialPortDemoController.swift
//  ORSSerialPortSwiftDemo
//
//  Created by Andrew Madsen on 10/31/14.
//  Copyright (c) 2014 Open Reel Software. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the
//	"Software"), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//	
//	The above copyright notice and this permission notice shall be included
//	in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Cocoa
class StreamReader  {
    
    let encoding : String.Encoding
    let chunkSize : Int
    var fileHandle : FileHandle!
    let delimData : Data
    var buffer : Data
    var atEof : Bool
    
    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {
        
        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }
    
    deinit {
        self.close()
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        // Read data chunks from file until a line delimiter is found:
        while !atEof {
            if let range = buffer.range(of: delimData) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                // EOF or read error.
                atEof = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension StreamReader : Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}


class StringWrapper: NSObject {
    var str: String
    init(str: String) {
        self.str = str
    }
}

extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    subscript (i: Int) -> String {
        return self[Range(i ..< i + 1)]
    }
    
    func substring(from: Int) -> String {
        return self[Range(min(from, length) ..< length)]
    }
    
    func substring(to: Int) -> String {
        return self[Range(0 ..< max(0, to))]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start ..< end)]
    }
    
}





class SerialPortDemoController: NSObject, ORSSerialPortDelegate, NSUserNotificationCenterDelegate {
	
	let serialPortManager = ORSSerialPortManager.shared()
	let availableBaudRates = [300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200, 230400]
	var shouldAddLineEnding = false
    var bind_check = "ff"
    var parameterId: StringWrapper = StringWrapper(str: "One")
    
    var sleeptime = 100000
    
    let DAC_ref = 2.9995
    let ADC_ref = 2.9995
    let R_sense_low = 0.68
    let R_sense_high = 0.16
    
    
    var clock_source = 1
    var IO = 0
    var capture  = 3
    
    var power_supply1_in_use = 0
    var power_supply2_in_use = 0
    var power_supply3_in_use = 0
    var power_supply4_in_use = 0
    var power_supply5_in_use = 0
    var power_supply6_in_use = 0
    var power_supply7_in_use = 0
    var BC1_in_use = 0
    var BC2_in_use = 0
    var BC3_in_use = 0
    var BC4_in_use = 0
    var BV1_in_use = 0
    var BV2_in_use = 0
    var BV3_in_use = 0
    var BV4_in_use = 0
    var NBV1_in_use = 0
    var NBV2_in_use = 0
    var POT2K5_in_use = 0
    var POT10K_in_use = 0

    var buffer: [String] = ["", "","", "","", "","", "","", "","", "","", "","", ""]
    
    
    var pin_state: [String] = ["", "","", "","", "","", "","", "","", "","", "","", ""]
    
    
	var serialPort: ORSSerialPort? {
		didSet {
			oldValue?.close()
			oldValue?.delegate = nil
			serialPort?.delegate = self
		}
	}
    
    
	
	@IBOutlet weak var sendTextField: NSTextField!
	@IBOutlet var receivedDataTextView: NSTextView!
	@IBOutlet weak var openCloseButton: NSButton!
	@IBOutlet weak var lineEndingPopUpButton: NSPopUpButton!
	var lineEndingString: String {
		let map = [0: "\r", 1: "\n", 2: "\r\n"]
		if let result = map[self.lineEndingPopUpButton.selectedTag()] {
			return result
		} else {
			return "\n"
		}
	}
	
	override init() {
		super.init()
		
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(serialPortsWereConnected(_:)), name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
		nc.addObserver(self, selector: #selector(serialPortsWereDisconnected(_:)), name: NSNotification.Name.ORSSerialPortsWereDisconnected, object: nil)

		NSUserNotificationCenter.default.delegate = self
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    



	@IBAction func send(_: AnyObject) {
		var string = self.sendTextField.stringValue
		if self.shouldAddLineEnding && !string.hasSuffix("\n") {
			string += self.lineEndingString
		}
        string +=  "\r\n"

		if let data = string.data(using: String.Encoding.utf8) {
			self.serialPort?.send(data)
		}
	}
	
	@IBAction func openOrClosePort(_ sender: AnyObject) {
		if let port = self.serialPort {
			if (port.isOpen) {
				port.close()
			} else {
				port.open()
				self.receivedDataTextView.textStorage?.mutableString.setString("");
			}
		}
	}
	
	// MARK: - ORSSerialPortDelegate
	
	func serialPortWasOpened(_ serialPort: ORSSerialPort) {
		self.openCloseButton.title = "Close"
	}
	
	func serialPortWasClosed(_ serialPort: ORSSerialPort) {
		self.openCloseButton.title = "Open"
	}
	
    


    
    
    
    var data_broken = 0
    var half_data = ""
    
    @IBAction func update(_ sender: NSButtonCell) {
        
        if (power_supply1_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call current ADC
            var string = "A00"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true

            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            string = "A01"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
            

            
        }

        
        if (power_supply2_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call current ADC
            var string = "A02"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
            
            usleep(useconds_t(sleeptime))


            //Call ADC voltage
            string = "A03"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
 
        }
        

        if (power_supply3_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call current ADC
            var string = "A04"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
            usleep(useconds_t(sleeptime))
            //Call ADC voltage
            string = "A05"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true

        }

        if (power_supply4_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call current ADC
            var string = "A06"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            string = "A07"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }

            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
        }
        

        if (power_supply5_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call current ADC
            var string = "A08"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            string = "A12"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }

            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
        }

        
        
        if (power_supply6_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call current ADC
            var string = "A13"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            usleep(useconds_t(sleeptime))
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
            //Call ADC voltage
            string = "A14"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }

            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
        }
        

        if (power_supply7_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            var string = "A15"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true

        }
        

        if (BC1_in_use == 1)
        {
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            var string = "A21"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true

        }

        if (BC2_in_use == 2)
        {
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            var string = "A22"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
        }

        
        if (BC3_in_use == 3)
        {
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            var string = "A20"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
        }
        

        if (BC4_in_use == 4)
        {
            usleep(useconds_t(sleeptime))

            //Call ADC voltage
            var string = "A23"
            if self.shouldAddLineEnding && !string.hasSuffix("\n") {
                string += self.lineEndingString
            }
            string +=  "\r\n"
            
            if let data = string.data(using: String.Encoding.utf8) {
                self.serialPort?.send(data)
            }
            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
            self.receivedDataTextView.needsDisplay = true
        }
        
    }
    
	func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
		if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            
            var in_data = String(string)
            

            
            if (in_data.lowercased().range(of:"@") != nil)
            {
                in_data = half_data + in_data + "\n"

                half_data = ""

                let endline = "\n"
                
                self.receivedDataTextView.textStorage?.mutableString.append(endline as String)
                self.receivedDataTextView.needsDisplay = true
            
                
                var fixed = String(in_data.characters.filter { !" @".characters.contains($0) })
                
                self.receivedDataTextView.textStorage?.mutableString.append(fixed as String)
                self.receivedDataTextView.needsDisplay = true
                
                //process data
                
                if(fixed[0] == "A")
                {
                    let ADC_num = Int(fixed[1 ..< 3])
                    let ADC_data_raw = Double(fixed[3 ..< 8])
                    
                    //Voltage Supply 1
                    if (ADC_num! == 1)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P1_voltage.title = String(format:"%.3f", ADC_voltage)
                    }
                    
                    //Voltage Supply 1current reading
                    if (ADC_num! == 0)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        let current = ADC_voltage/100.0/R_sense_low
                        
                        //Update the current reading in mA
                        P1_current.title = String(format:"%.1f", current * 1000)
                        
                    }
                    //Voltage Supply 2
                    if (ADC_num! == 3)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P2_voltage.title = String(format:"%.3f", ADC_voltage)
                        
                    }
                    
                    
                    //Voltage Supply 2 current reading
                    if (ADC_num! == 2)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        let current = ADC_voltage/100.0/R_sense_low
                        
                        //Update the current reading in mA
                        P2_current.title = String(format:"%.1f", current * 1000)
                    }
                    
                    //Voltage Supply 3
                    if (ADC_num! == 5)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P3_voltage.title = String(format:"%.3f", ADC_voltage)
                    }
                    
                    
                    //Voltage Supply 3 current reading
                    if (ADC_num! == 4)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        let current = ADC_voltage/100.0/R_sense_low
                        
                        //Update the current reading in mA
                        P3_current.title = String(format:"%.1f", current * 1000)
                    }
                    //Voltage Supply 4
                    if (ADC_num! == 7)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P4_voltage.title = String(format:"%.3f", ADC_voltage)
                    }
                    
                    
                    //Voltage Supply 4 current reading
                    if (ADC_num! == 6)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        let current = ADC_voltage/100.0/R_sense_low
                        
                        //Update the current reading in mA
                        P4_current.title = String(format:"%.1f", current * 1000)
                    }
                    
                    //Voltage Supply 5
                    if (ADC_num! == 12)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P5_voltage.title = String(format:"%.3f", ADC_voltage)
                    }
                    
                    
                    //Voltage Supply 5 current reading
                    if (ADC_num! == 8)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        let current = ADC_voltage/100.0/R_sense_high
                        
                        //Update the current reading in mA
                        P5_current.title = String(format:"%.1f", current * 1000)
                    }
                    
                    //Voltage Supply 6
                    if (ADC_num! == 14)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P6_voltage.title = String(format:"%.3f", ADC_voltage)
                    }
                    
                    //Voltage Supply 6 current
                    if (ADC_num! == 13)
                    {
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        let current = ADC_voltage/100.0/R_sense_high
                        
                        //Update the current reading in mA
                        P6_current.title = String(format:"%.1f", current * 1000)
                    }
                    
                    
                    //Voltage Supply FOR LEVEL SHIFTER
                    if (ADC_num! == 15)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        //Update the voltage reading
                        P7_voltage.title = String(format:"%.3f", ADC_voltage)
                    }
                    
                    
                    
                    if (ADC_num! == 21)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        //Gain = 1.0+95.3/4.99
                        let current = ADC_voltage/(1.0+54.9/4.99)/200.0
                        
                        //Update the current reading in uA
                        BC1_text.title = String(format:"%.1f", current * 1000000.0)
                    }
                    
                    if (ADC_num! == 22)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        //Gain = 1.0+95.3/4.99
                        let current = ADC_voltage/(1.0+54.9/4.99)/200.0
                        
                        //Update the current reading in uA
                        BC2_text.title = String(format:"%.1f", current * 1000000.0)
                    }
                    
                    
                    
                    if (ADC_num! == 20)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        //Gain = 1.0+95.3/4.99
                        let current = ADC_voltage/(1.0+54.9/4.99)/200.0
                        
                        //Update the current reading in uA
                        BC3_text.title = String(format:"%.1f", current * 1000000.0)
                    }
                    
                    
                    if (ADC_num! == 23)
                    {
                        //Convert to voltage
                        let ADC_voltage = ADC_data_raw!/16384.0 * ADC_ref
                        
                        //Convert to current = ADC/Gain/R_sense
                        //Gain = 1.0+95.3/4.99
                        let current = ADC_voltage/(1.0+54.9/4.99)/200.0
                        
                        //Update the current reading in uA
                        BC4_text.title = String(format:"%.1f", current * 1000000.0)
                    }
                    
                }
                else if(fixed[0] == "G" && fixed[1] == "D")
                {
                    
                    let GPIO_num = Int(fixed[2 ..< 4])
                    
                    fixed = String(fixed.characters.filter { !" \n\t\r".characters.contains($0) })
                    
                    
                    let data_length = fixed.characters.count
                    buffer[GPIO_num!] = buffer[GPIO_num!] + fixed[0 ..< data_length+1]

                    
                }else
                {
                    
                }
                

                
                
            }
            else
            {
                let fixed = String(in_data.characters.filter { !" \n\t\r".characters.contains($0) })
                half_data =  half_data + fixed
                
            }


	}
}
    
	 
	func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
		self.serialPort = nil
		self.openCloseButton.title = "Open"
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
		print("SerialPort \(serialPort) encountered an error: \(error)")
	}
	
	// MARK: - NSUserNotifcationCenterDelegate
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
		let popTime = DispatchTime.now() + Double(Int64(3.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
			center.removeDeliveredNotification(notification)
		}
	}
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}
	
	// MARK: - Notifications
	
	func serialPortsWereConnected(_ notification: Notification) {
		if let userInfo = notification.userInfo {
			let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
			print("Ports were connected: \(connectedPorts)")
			self.postUserNotificationForConnectedPorts(connectedPorts)
		}
	}
	
	func serialPortsWereDisconnected(_ notification: Notification) {
		if let userInfo = notification.userInfo {
			let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
			print("Ports were disconnected: \(disconnectedPorts)")
			self.postUserNotificationForDisconnectedPorts(disconnectedPorts)
		}
	}
	
	func postUserNotificationForConnectedPorts(_ connectedPorts: [ORSSerialPort]) {
		let unc = NSUserNotificationCenter.default
		for port in connectedPorts {
			let userNote = NSUserNotification()
			userNote.title = NSLocalizedString("Serial Port Connected", comment: "Serial Port Connected")
			userNote.informativeText = "Serial Port \(port.name) was connected to your Mac."
			userNote.soundName = nil;
			unc.deliver(userNote)
		}
	}
	
	func postUserNotificationForDisconnectedPorts(_ disconnectedPorts: [ORSSerialPort]) {
		let unc = NSUserNotificationCenter.default
		for port in disconnectedPorts {
			let userNote = NSUserNotification()
			userNote.title = NSLocalizedString("Serial Port Disconnected", comment: "Serial Port Disconnected")
			userNote.informativeText = "Serial Port \(port.name) was disconnected from your Mac."
			userNote.soundName = nil;
			unc.deliver(userNote)
		}
	}
    
    //Variable Resistor Start
    
    @IBOutlet weak var slidebar_2k5: NSSliderCell!
    @IBOutlet weak var slidebar_10k: NSSliderCell!
    
    @IBOutlet weak var text_2k5: NSTextFieldCell!
    @IBOutlet weak var text_10k: NSTextFieldCell!
    
    
    @IBOutlet weak var POT2K5_offset: NSTextFieldCell!
    
    
    @IBOutlet weak var POT2K5_X: NSTextFieldCell!
    @IBOutlet weak var POT10K_offset: NSTextFieldCell!
    
    @IBOutlet weak var POT10K_X: NSTextFieldCell!
    @IBAction func set_2k5(_ sender: AnyObject?) {
        
        POT2K5_in_use = 1
        
        let offset = Double(POT2K5_offset.title)! / 2500.0 * 255.0
        
        let X = Double(POT2K5_X.title)!
        
        
        //Calculate the expected resistance
        text_2k5.title = String(Int(slidebar_2k5.doubleValue / 255 * 2500))
        
    
        var slidebar_value = (Double(slidebar_2k5.integerValue)
            + offset) * X
        

        if slidebar_value > 255
        {
            slidebar_value = 255
        }
        
        
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "7"  //POT Chip ID 1-8
        string += "2"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        string +=  "\r\n"
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        
        
    }
    
    @IBAction func set_10k(_ sender: AnyObject?) {
        
        POT10K_in_use = 1

        let offset = Double(POT10K_offset.title)! / 10000.0 * 255.0
        
        let X = Double(POT10K_X.title)!
        
        
        //Calculate the expected resistance
        text_10k.title = String(Int(slidebar_10k.doubleValue / 255 * 10000))
        
  
        
        //APPLY OFFSET
        var slidebar_value = (slidebar_10k.doubleValue + offset) * X

        if slidebar_value > 255.0
        {
            slidebar_value = 255.0
        }
        
        
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "8"  //POT Chip ID 1-8
        string += "2"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
         self.serialPort?.send(data)
         }
    }
    //Variable Resistor end
    
    
    @IBOutlet weak var P2_offset: NSTextFieldCell!
    
    
    @IBOutlet weak var P3_offset: NSTextFieldCell!
    
    @IBOutlet weak var P4_offset: NSTextFieldCell!
    
    
    @IBOutlet weak var P5_offset: NSTextFieldCell!
   
    @IBOutlet weak var P6_offset: NSTextFieldCell!
    
    @IBOutlet weak var P7_offset: NSTextFieldCell!
    
    @IBOutlet weak var P2_X: NSTextFieldCell!
    
    @IBOutlet weak var P3_X: NSTextFieldCell!
    
    
    @IBOutlet weak var P4_X: NSTextFieldCell!
    
    @IBOutlet weak var P5_X: NSTextFieldCell!
    
    
    @IBOutlet weak var P6_X: NSTextFieldCell!
    
    @IBOutlet weak var P7_X: NSTextFieldCell!
    
    //Voltge Supply Start

    @IBOutlet weak var P1_input: NSTextFieldCell!
    
    @IBOutlet weak var P1_voltage: NSTextFieldCell!
    
    @IBOutlet weak var P1_current: NSTextFieldCell!
    
    @IBOutlet weak var P1_offset: NSTextFieldCell!
    
    @IBOutlet weak var P1_X: NSTextFieldCell!
    
    
    @IBAction func P1_set(_ sender: AnyObject?) {
        
        power_supply1_in_use = 1

        var voltage = Double(P1_input.title)
        
        //Apply offset and scaling factor
        
        voltage = voltage! + Double(P1_offset.title)!
        
        voltage = voltage! * Double(P1_X.title)!
        
        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "1"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        string +=  "\r\n"
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
         self.serialPort?.send(data)
         }
        
        

        usleep(300000)

        //Call current and voltage readings
        string = "A00\r\n"
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        usleep(300000)

        //Call ADC voltage
        string = "A01\r\n"
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
 
        
    }
    
    @IBOutlet weak var P2_input: NSTextFieldCell!
    
    @IBOutlet weak var P2_voltage: NSTextFieldCell!
    
    @IBOutlet weak var P2_current: NSTextFieldCell!
    
    @IBAction func P2_set(_ sender: AnyObject?) {
        
        power_supply2_in_use = 1
        
        var voltage = Double(P2_input.title)
        voltage = voltage! + Double(P2_offset.title)!
        
        voltage = voltage! * Double(P2_X.title)!
        

        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "2"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        
        usleep(100000)
        
        //Call current and voltage readings
        string = "A02"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        usleep(100000)
        
        //Call ADC voltage
        string = "A03"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        
        
    }
    
    
    
    @IBOutlet weak var P3_input: NSTextFieldCell!
    
    @IBOutlet weak var P3_current: NSTextFieldCell!
    @IBOutlet weak var P3_voltage: NSTextFieldCell!
    
    @IBAction func P3_set(_ sender: AnyObject?) {
        power_supply3_in_use = 1

        
        var voltage = Double(P3_input.title)

        voltage = voltage! + Double(P3_offset.title)!
        
        voltage = voltage! * Double(P3_X.title)!
        
        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "3"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"
        
        //Log this message to the window
        
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
 
        
        usleep(100000)
        
        //Call current and voltage readings
        string = "A04"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }

        
        usleep(100000)
        
        //Call ADC voltage
        
        string = "A05"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
 
        
        
    }
    
    @IBOutlet weak var P4_input: NSTextFieldCell!
    
    @IBOutlet weak var P4_voltage: NSTextFieldCell!
    
    @IBOutlet weak var P4_current: NSTextFieldCell!
    
    
    @IBAction func P4_set(_ sender: AnyObject?) {
        
        power_supply4_in_use = 1

        var voltage = Double(P4_input.title)
        
        voltage = voltage! + Double(P4_offset.title)!
        
        voltage = voltage! * Double(P4_X.title)!

        
        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "4"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"
        
      
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        usleep(100000)

        //Call current and voltage readings
        string = "A06"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        usleep(100000)
        
        //Call ADC voltage
        string = "A07"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
 
        
    }
    

    @IBOutlet weak var P5_input: NSTextFieldCell!
    //Voltage Supply End

    @IBOutlet weak var P5_voltage: NSTextFieldCell!
    
    @IBOutlet weak var P5_current: NSTextFieldCell!
    
    @IBAction func P5_set(_ sender: AnyObject?) {
        
        power_supply5_in_use = 1

        
        
        var voltage = Double(P5_input.title)
        
        voltage = voltage! + Double(P5_offset.title)!
        
        voltage = voltage! * Double(P5_X.title)!
        
        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "5"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        //End of the message
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        
        
        usleep(300000)
        
        //Call current and voltage readings
        string = "A08"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        usleep(300000)
        
        //Call ADC voltage
        string = "A12"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
 
        
        
    }
    
    @IBOutlet weak var P6_input: NSTextFieldCell!
    @IBOutlet weak var P6_voltage: NSTextFieldCell!
    
    @IBOutlet weak var P6_current: NSTextFieldCell!
    
    @IBAction func P6_set(_ sender: AnyObject?) {
        
        power_supply6_in_use = 1

        
        var voltage = Double(P6_input.title)
        voltage = voltage! + Double(P6_offset.title)!
        
        voltage = voltage! * Double(P6_X.title)!

        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "6"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        string +=  "\r\n"
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(100000)
        
        //Call current and voltage readings
        string = "A13"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
        usleep(100000)
        
        //Call ADC voltage
        string = "A14"
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
    }
    
    @IBOutlet weak var PS7_input: NSTextFieldCell!
    
    @IBOutlet weak var P7_voltage: NSTextFieldCell!
    @IBAction func PS7_set(_ sender: AnyObject?) {
        power_supply7_in_use = 1
        
        
        var voltage = Double(PS7_input.title)
        
        
        voltage = voltage! + Double(P7_offset.title)!
        
        voltage = voltage! * Double(P7_X.title)!

        let R1 = (voltage!/0.5 - 1.0) * 500.0
        
        //R1 = R1 * 500.0
        let slidebar_value = R1/2500.0 * 255.0
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "P"  //POT Identified
        string += "7"  //POT Chip ID 1-8
        string += "1"  //POT Channel 1-2
        //Add the value
        string += String(format:"%02X",Int(slidebar_value))
        //End of the message
        string +=  "\r\n"
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(100000)
        
        //Call voltage readings
        string = "A15"
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
    }
    
    //Bias Voltage/Current Start
    @IBOutlet weak var BV1_input: NSTextFieldCell!
    @IBOutlet weak var BV1_text: NSTextFieldCell!
    @IBOutlet weak var BV2_input: NSTextFieldCell!
    @IBOutlet weak var BV2_text: NSTextFieldCell!
    @IBOutlet weak var BV3_input: NSTextFieldCell!
    @IBOutlet weak var BV3_text: NSTextFieldCell!
    @IBOutlet weak var BV4_input: NSTextFieldCell!
    @IBOutlet weak var BV4_text: NSTextFieldCell!
    @IBOutlet weak var NBV1_input: NSTextFieldCell!
    @IBOutlet weak var NBV1_text: NSTextFieldCell!
    @IBOutlet weak var NBV2_input: NSTextFieldCell!
    @IBOutlet weak var NBV2_text: NSTextFieldCell!
    @IBOutlet weak var BC1_input: NSTextFieldCell!
    @IBOutlet weak var BC1_text: NSTextFieldCell!
    @IBOutlet weak var BC2_input: NSTextFieldCell!
    @IBOutlet weak var BC2_text: NSTextFieldCell!
    @IBOutlet weak var BC3_input: NSTextFieldCell!
    @IBOutlet weak var BC3_text: NSTextFieldCell!
    @IBOutlet weak var BC4_input: NSTextFieldCell!
    @IBOutlet weak var BC4_text: NSTextFieldCell!
    
    
    @IBOutlet weak var BV1_offset: NSTextFieldCell!
    
    @IBOutlet weak var BV2_offset: NSTextFieldCell!
    
    @IBOutlet weak var BV3_offset: NSTextFieldCell!
    
    @IBOutlet weak var BV4_offset: NSTextFieldCell!
    
    @IBOutlet weak var NBV1_offset: NSTextFieldCell!
 
    @IBOutlet weak var NBV2_offset: NSTextFieldCell!
    
    @IBOutlet weak var BC1_offset: NSTextFieldCell!
    
    @IBOutlet weak var BC2_offset: NSTextFieldCell!
    
    @IBOutlet weak var BC3_offset: NSTextFieldCell!
    
    @IBOutlet weak var BC4_offset: NSTextFieldCell!
    
    @IBOutlet weak var BV1_X: NSTextFieldCell!
    
    @IBOutlet weak var BV2_X: NSTextFieldCell!
    
    @IBOutlet weak var BV3_X: NSTextFieldCell!
    
    @IBOutlet weak var BV4_X: NSTextFieldCell!
    
    @IBOutlet weak var NBV1_X: NSTextFieldCell!
 
    @IBOutlet weak var NBV2_X: NSTextFieldCell!
    
    
    @IBOutlet weak var BC1_X: NSTextFieldCell!
    
    @IBOutlet weak var BC2_X: NSTextFieldCell!
    
    @IBOutlet weak var BC3_X: NSTextFieldCell!
  
    @IBOutlet weak var BC4_X: NSTextFieldCell!
    
    @IBAction func BV1_set(_ sender: AnyObject?) {
        
        BV1_in_use = 1
        
        var input = Double(BV1_input.title)
        BV1_text.title = String(format:"%.4f",input!)

        
        input = input! + Double(BV1_offset.title)!
        
        input = input! * Double(BV1_X.title)!
        
        BV1_text.title = String(format:"%.4f",input!)
        
        if input! > DAC_ref
        {
            input = DAC_ref
        }
      
        let Code = input!/DAC_ref * 65535
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "1"  //DAC ID 1-3
        string += "1"  //Channel 1-4

        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
         self.serialPort?.send(data)
        }
        
        
    }
    
    
    @IBAction func BV2_set(_ sender: AnyObject?) {
        BV2_in_use = 1
        
        var input = Double(BV2_input.title)
        input = input! + Double(BV2_offset.title)!
        
        input = input! * Double(BV2_X.title)!
        
        BV2_text.title = String(format:"%.4f",input!)
            
        
        if input! > DAC_ref
        {
            input = DAC_ref
        }
        
        
        let Code = input!/DAC_ref * 65535
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "1"  //DAC ID 1-3
        string += "2"  //Channel 1-4
        
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
         self.serialPort?.send(data)
         }
        
    }
    
    @IBAction func BV3_set(_ sender: AnyObject?) {
        BV3_in_use = 1

        var input = Double(BV3_input.title)
        input = input! + Double(BV3_offset.title)!
        
        input = input! * Double(BV3_X.title)!
        
        BV3_text.title = String(format:"%.4f",input!)
        
        if input! > DAC_ref
        {
            input = DAC_ref
        }
        
        let Code = input!/DAC_ref * 65535
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "1"  //DAC ID 1-3
        string += "3"  //Channel 1-4
        
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
    }
    
    @IBAction func BV4_set(_ sender: AnyObject?) {
        BV4_in_use = 1

        
        var input = Double(BV4_input.title)
        input = input! + Double(BV4_offset.title)!
        
        input = input! * Double(BV4_X.title)!
        
        BV4_text.title = String(format:"%.4f",input!)

        if input! > DAC_ref
        {
            input = DAC_ref
        }
        
        let Code = input!/DAC_ref * 65535
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "1"  //DAC ID 1-3
        string += "4"  //Channel 1-4
        
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
    }
    
    @IBAction func NBV1_set(_ sender: AnyObject?) {
        NBV1_in_use = 1

        
        var input = Double(NBV1_input.title)! * -1
        
        if input < 0 {
            input = input * -1
        }
 
        var Offset = Double(NBV1_offset.title)! * -1
        
        if Offset < 0 {
            Offset = Offset * -1
        }
        
        input = input + Offset
        input = input * Double(NBV1_X.title)!
        
        NBV1_text.title = String(format:"%.4f",input * -1)
        
        if input > DAC_ref
        {
            input = DAC_ref
        }
        
        let Code = input/DAC_ref * 65535
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "3"  //DAC ID 1-3
        string += "1"  //Channel 1-4
        
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
    }
    
    @IBAction func NBV2_set(_ sender: AnyObject?) {
        NBV2_in_use = 1

        var input = Double(NBV2_input.title)! * -1
        
        if input < 0 {
            input = input * -1
        }
        
        var Offset = Double(NBV2_offset.title)! * -1
        
        if Offset < 0 {
            Offset = Offset * -1
        }
        
        input = input + Offset
        input = input * Double(NBV2_X.title)!
        
        NBV2_text.title = String(format:"%.4f",input * -1)
        
        if input > DAC_ref
        {
            input = DAC_ref
        }

        let Code = input/DAC_ref * 65535
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "3"  //DAC ID 1-3
        string += "3"  //Channel 1-4
        
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
    }
    
    //Bias Voltage End
 
    //Bias Current  Start
    
    @IBAction func BC1_set(_ sender: AnyObject?) {
        
        BC1_in_use = 1

        var input = Double(BC1_input.title)
        input = input! + Double(BC1_offset.title)!
        
        input = input! * Double(BC1_X.title)!
        

        var voltage = input! * (0.000001) * 200 * (4.99 + 45.3)/4.99
        
        if voltage > DAC_ref
        {
            voltage = DAC_ref
        }
        let Code = voltage/DAC_ref * 65535.0

        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "2"  //DAC ID 1-3
        string += "1"  //Channel 2
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
         self.serialPort?.send(data)
         }
        
        /*
        usleep(useconds_t(sleeptime))
        
        //Call current and voltage readings
        string = "A21"
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(sleeptime))
 */

        
    }
    
    
    @IBAction func BC2_set(_ sender: AnyObject?) {
        BC2_in_use = 1

        var input = Double(BC2_input.title)
        input = input! + Double(BC2_offset.title)!
        
        input = input! * Double(BC2_X.title)!

        
        var voltage = input! * (0.000001) * 200 * (4.99 + 45.3)/4.99
        
        if voltage > DAC_ref
        {
            voltage = DAC_ref
        }
        let Code = voltage/DAC_ref * 65535.0
        
        //Creat message string
        var string = ""
        
//Formating the Message
        string += "D"  //DAC Identified
        string += "2"  //DAC ID 1-3
        string += "2"  //Channel 2
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
         self.serialPort?.send(data)
         }

        /*
        usleep(useconds_t(sleeptime))
        
        //Call current and voltage readings
        string = "A22"
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(sleeptime))
 */

    }

    @IBAction func BC3_set(_ sender: AnyObject?) {
        
        BC3_in_use = 1
        
        var input = Double(BC3_input.title)
        input = input! + Double(BC3_offset.title)!
        
        input = input! * Double(BC3_X.title)!

        
        var voltage = input! * (0.000001) * 200 * (4.99 + 45.3)/4.99
        
        if voltage > DAC_ref
        {
            voltage = DAC_ref
        }
        let Code = voltage/DAC_ref * 65535.0
        
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "2"  //DAC ID 1-3
        string += "3"  //Channel 2
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        
          /*
        usleep(useconds_t(sleeptime))
        
        //Call current and voltage readings
        string = "A20"
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(sleeptime))
 */
    }
    
    
    
    @IBAction func BC4_set(_ sender: AnyObject?) {
        
        
        BC4_in_use = 1

        var input = Double(BC4_input.title)
        input = input! + Double(BC4_offset.title)!
        
        input = input! * Double(BC4_X.title)!

        
        var voltage = input! * (0.000001) * 200 * (4.99 + 45.3)/4.99
        
        
        if voltage > DAC_ref
        {
            voltage = DAC_ref
        }
        let Code = voltage/DAC_ref * 65535.0
        
        //Creat message string
        var string = ""
        
        //Formating the Message
        string += "D"  //DAC Identified
        string += "2"  //DAC ID 1-3
        string += "4"  //Channel 2
        string += String(format:"%04X",Int(Code))
        
        //End of the message
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(sleeptime))
        
        //Call current and voltage readings
        string = "A23"
        if self.shouldAddLineEnding && !string.hasSuffix("\n") {
            string += self.lineEndingString
        }
        string +=  "\r\n"

        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(sleeptime))

    }
    
    
    
    //Bias Current End
    
    @IBAction func Save_State(_ sender: NSButtonCell) {
        let directoryName = "DC_board_state_folder"
        
        
        //let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                          // .userDomainMask, true)
       // let documentsDirectory = dirPaths[0] as! String
        
        //try! FileManager.default.createDirectory(atPath: documentsDirectory, withIntermediateDirectories: false, attributes: nil)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        
        let dirURL = documentsURL?.appendingPathComponent(directoryName)
        
        guard let dirpath = dirURL?.path else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: dirpath) {
            try! FileManager.default.createDirectory(atPath: dirpath, withIntermediateDirectories: false, attributes: nil)
        } else {
        }
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date as Date)
        
        let month = calendar.component(.month, from: date as Date)
        let day = calendar.component(.day, from: date as Date)

        let hour = calendar.component(.hour, from: date as Date)
        let minutes = calendar.component(.minute, from: date as Date)
        
        
       // let fileame = year.description + "_"+ month.description+ "_" + day.description + "_" + hour.description + "_" + minutes.description + "_state_file.csv"
        
        var filename = year.description + "_"
        filename = filename + month.description + "_"
        filename = filename + day.description + "_"
        filename = filename + hour.description + "_"
        filename = filename + minutes.description + "_"
        filename = filename + "_state_file.csv"
        
        
        let fileURL = dirURL?.appendingPathComponent(filename)

        
        var string = ",Load,Offset,Scaling,Enable\r\n"
        
        

        string = string + "PS1," + P1_input.title + "," + P1_offset.title + "," + P1_X.title + "," + String(power_supply1_in_use) + "\n"
        

        string =  string + "PS2," + P2_input.title + "," + P2_offset.title + "," + P2_X.title + "," + String(power_supply2_in_use) + "\n"
        
        
        string =  string + "PS3," + P3_input.title + "," + P3_offset.title + "," + P3_X.title + "," + String(power_supply3_in_use) + "\n"
        
        string = string + "PS4," + P4_input.title + "," + P4_offset.title + "," + P4_X.title + "," + String(power_supply4_in_use) + "\n"
        
        
        string =  string + "PS5," + P5_input.title + "," + P5_offset.title + "," + P5_X.title + "," + String(power_supply5_in_use) + "\n"

        string = string + "PS6," + P6_input.title + "," + P6_offset.title + "," + P6_X.title + "," + String(power_supply6_in_use) + "\n"
        
        
        string =  string + "PS7," + PS7_input.title + "," + P7_offset.title + "," + P7_X.title + "," + String(power_supply7_in_use) + "\n"
        
         string =  string + "BV1," + BV1_input.title + "," + BV1_offset.title + "," + BV1_X.title + "," + String(BV1_in_use) + "\n"

         string =  string + "BV2," + BV2_input.title + "," + BV2_offset.title + "," + BV2_X.title + "," + String(BV2_in_use) + "\n"
        
        string =  string + "BV3," + BV3_input.title + "," + BV3_offset.title + "," + BV3_X.title + "," + String(BV3_in_use) + "\n"
        
        string =  string + "BV4," + BV4_input.title + "," + BV4_offset.title + "," + BV4_X.title + "," + String(BV4_in_use) + "\n"

        string =  string + "NBV1," + NBV1_input.title + "," + NBV1_offset.title + "," + NBV1_X.title + "," + String(NBV1_in_use) + "\n"
        
        string =  string + "NBV2," + NBV2_input.title + "," + NBV2_offset.title + "," + NBV2_X.title + "," + String(NBV2_in_use) + "\n"
        
        
        string =  string + "BC1," + BC1_input.title + "," + BC1_offset.title + "," + BC1_X.title + "," + String(BC1_in_use) + "\n"

        string =  string + "BC2," + BC2_input.title + "," + BC2_offset.title + "," + BC2_X.title + "," + String(BC2_in_use) + "\n"

        string =  string + "BC3," + BC3_input.title + "," + BC3_offset.title + "," + BC3_X.title + "," + String(BC3_in_use) + "\n"
        
        string =  string + "BC4," + BC4_input.title + "," + BC4_offset.title + "," + BC4_X.title + "," + String(BC4_in_use) + "\n"

        string =  string + "POT2K5," + text_2k5.title + "," + POT2K5_offset.title + "," + POT2K5_X.title + "," + String(POT2K5_in_use) + "\n"
        
        string =  string + "POT10K," + text_10k.title + "," + POT10K_offset.title + "," + POT10K_X.title + "," + String(POT10K_in_use) + "\n"
        
        
        
        
        try! string.write(to: fileURL!, atomically: true, encoding: String.Encoding.macOSRoman)
        
        string = "State File saved to" + (fileURL?.path)!
        
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true

    }
    

    
    @IBAction func Load_State(_ sender: NSButtonCell) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                
                guard let filepath =  openPanel.url?.path else {
                    return
                }
                
                let file_reader = StreamReader(path:filepath)
                var line = file_reader?.nextLine()
                
                while 1 == 1
                {
                    line = file_reader?.nextLine()
                    
                    if line == nil
                    {
                        break
                    }
                    
                    let items = line?.components(separatedBy: ",")
                    let item1 = items?[0]
                    let item2 = items?[1]
                    let item3 = items?[2]
                    let item4 = items?[3]
                    let item5 = items?[4]

                    let ID = item1!
                    let value = item2!
                    let offset = item3!
                    let X = item4!
                    let enabled = Int(item5!)

                    switch ID {
                    case "PS1":
                        self.P1_input.title = value
                        self.P1_offset.title = offset
                        self.P1_X.title = X
                        self.power_supply1_in_use = enabled!
                        if self.power_supply1_in_use == 1
                        {
                            
                            var string = "Preloading P1 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                            self.P1_set(nil)

                        }
                        

                        

                    case "PS2":
                        self.P2_input.title = value
                        self.P2_offset.title = offset
                        self.P2_X.title = X
                        self.power_supply2_in_use = enabled!
                        if self.power_supply2_in_use == 1
                        {
                            var string = "Preloading P2 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                            self.P2_set(nil)
                            
                            
                        }
                        
                        
                    case "PS3":
                        self.P3_input.title = value
                        self.P3_offset.title = offset
                        self.P3_X.title = X
                        self.power_supply3_in_use = enabled!
                        if self.power_supply3_in_use == 1
                        {
                            var string = "Preloading P3 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                            
                            self.P3_set(nil)
                        }
                        
                    case "PS4":
                        self.P4_input.title = value
                        self.P4_offset.title = offset
                        self.P4_X.title = X
                        self.power_supply4_in_use = enabled!
                        if self.power_supply4_in_use == 1
                        {
                            var string = "Preloading P4 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                            
                            self.P4_set(nil)
                        }
                        
                    case "PS5":
                        self.P5_input.title = value
                        self.P5_offset.title = offset
                        self.P5_X.title = X
                        self.power_supply5_in_use = enabled!
                        if self.power_supply5_in_use == 1
                        {
                            var string = "Preloading P5 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.P5_set(nil)
                        }
                    case "PS6":
                        self.P6_input.title = value
                        self.P6_offset.title = offset
                        self.P6_X.title = X
                        self.power_supply6_in_use = enabled!
                        if self.power_supply6_in_use == 1
                        {
                            var string = "Preloading P6 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.P6_set(nil)
                        }
                    case "PS7":
                        self.PS7_input.title = value
                        self.P7_offset.title = offset
                        self.P7_X.title = X
                        self.power_supply7_in_use = enabled!
                        if self.power_supply7_in_use == 1
                        {
                            var string = "Preloading Level shifter to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.PS7_set(nil)
                        }
                        
                    case "BV1":
                        self.BV1_input.title = value
                        self.BV1_offset.title = offset
                        self.BV1_X.title = X
                        self.BV1_in_use = enabled!
                        if self.BV1_in_use == 1
                        {
                            var string = "Preloading Bias Voltage 1 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BV1_set(nil)
                        }

                    case "BV2":
                        self.BV2_input.title = value
                        self.BV2_offset.title = offset
                        self.BV2_X.title = X
                        self.BV2_in_use = enabled!
                        if self.BV2_in_use == 1
                        {
                            var string = "Preloading Bias Voltage 2 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                            self.BV2_set(nil)
                        }
                        
                    case "BV3":
                        self.BV3_input.title = value
                        self.BV3_offset.title = offset
                        self.BV3_X.title = X
                        self.BV3_in_use = enabled!
                        if self.BV3_in_use == 1
                        {
                            var string = "Preloading Bias Voltage 3 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BV3_set(nil)
                        }
                        
                    case "BV4":
                        self.BV4_input.title = value
                        self.BV4_offset.title = offset
                        self.BV4_X.title = X
                        self.BV4_in_use = enabled!
                        if self.BV4_in_use == 1
                        {
                            var string = "Preloading Bias Voltage 4 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BV4_set(nil)
                        }
                        
                    case "NBV1":
                        self.NBV1_input.title = value
                        self.NBV1_offset.title = offset
                        self.NBV1_X.title = X
                        self.NBV1_in_use = enabled!
                        if self.NBV1_in_use == 1
                        {
                            var string = "Preloading Negtive Bias Voltage 1 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.NBV1_set(nil)
                        }
                        
                    case "NBV2":
                        self.NBV2_input.title = value
                        self.NBV2_offset.title = offset
                        self.NBV2_X.title = X
                        self.NBV2_in_use = enabled!
                        if self.NBV2_in_use == 1
                        {
                            var string = "Preloading Negtive Bias Voltage 2 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.NBV2_set(nil)
                        }
                        
                        
                    case "BC1":
                        self.BC1_input.title = value
                        self.BC1_offset.title = offset
                        self.BC1_X.title = X
                        self.BC1_in_use = enabled!
                        if self.BC1_in_use == 1
                        {
                            var string = "Preloading Bias Current 1 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BC1_set(nil)
                        }
                        
                    case "BC2":
                        self.BC2_input.title = value
                        self.BC2_offset.title = offset
                        self.BC2_X.title = X
                        self.BC2_in_use = enabled!
                        if self.BC2_in_use == 1
                        {
                            var string = "Preloading Bias Current 2 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BC2_set(nil)
                        }
                        
                    case "BC3":
                        self.BC3_input.title = value
                        self.BC3_offset.title = offset
                        self.BC3_X.title = X
                        self.BC3_in_use = enabled!
                        if self.BC3_in_use == 1
                        {
                            var string = "Preloading Bias Current 3 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BC3_set(nil)
                        }
                        
                    case "BC4":
                        self.BC4_input.title = value
                        self.BC4_offset.title = offset
                        self.BC4_X.title = X
                        self.BC4_in_use = enabled!
                        if self.BC4_in_use == 1
                        {
                            var string = "Preloading Bias Current 4 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.BC4_set(nil)
                        }
                        
                        
                    case "POT2K5":
                        
                        self.slidebar_2k5.integerValue = Int(Double(value)! / 2500.0 * 255.0)
                        
                        self.POT2K5_offset.title = offset
                        self.POT2K5_X.title = X
                        self.POT2K5_in_use = enabled!
                        if self.POT2K5_in_use == 1
                        {
                            var string = "Preloading POT 2K5 to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.set_2k5(nil)
                        }
                        
                        
                    case "POT10K":
                        
                        self.slidebar_10k.integerValue = Int(Double(value)! / 10000.0 * 255.0)
                        
                        self.POT10K_offset.title = offset
                        self.POT10K_X.title = X
                        self.POT10K_in_use = enabled!
                        if self.POT10K_in_use == 1
                        {
                            var string = "Preloading POT 10K to " + value
                            string = string + "\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            self.set_10k(nil)
                        }
                        
                        
                    default:
                        print("Some other character")
                    }
                    
                    
                    
                    
                }

            }
        }
        
        
        
    }
    
    let terminal_char = "\0"
    @IBOutlet weak var gpio1_in: NSButtonCell!
    @IBOutlet weak var gpio2_in: NSButtonCell!
    @IBOutlet weak var gpio3_in: NSButtonCell!
    @IBOutlet weak var gpio4_in: NSButtonCell!
    @IBOutlet weak var gpio5_in: NSButtonCell!
    @IBOutlet weak var gpio6_in: NSButtonCell!
    @IBOutlet weak var gpio7_in: NSButtonCell!
    @IBOutlet weak var gpio8_in: NSButtonCell!
    @IBOutlet weak var gpio9_in: NSButtonCell!
    @IBOutlet weak var gpio10_in: NSButtonCell!
    @IBOutlet weak var gpio11_in: NSButtonCell!
    @IBOutlet weak var gpio12_in: NSButtonCell!
    @IBOutlet weak var gpio13_in: NSButtonCell!
    @IBOutlet weak var gpio14_in: NSButtonCell!
    @IBOutlet weak var gpio15_in: NSButtonCell!
    @IBOutlet weak var gpio16_in: NSButtonCell!
    @IBOutlet weak var gpio1_out: NSButtonCell!
    @IBOutlet weak var gpio2_out: NSButtonCell!
    
    @IBOutlet weak var gpio3_out: NSButtonCell!
    @IBOutlet weak var gpio4_out: NSButtonCell!
    @IBOutlet weak var gpio5_out: NSButtonCell!
    @IBOutlet weak var gpio6_out: NSButtonCell!
    @IBOutlet weak var gpio7_out: NSButtonCell!
    @IBOutlet weak var gpio8_out: NSButtonCell!
    @IBOutlet weak var gpio9_out: NSButtonCell!
    @IBOutlet weak var gpio10_out: NSButtonCell!
    @IBOutlet weak var gpio11_out: NSButtonCell!
    @IBOutlet weak var gpio12_out: NSButtonCell!
    @IBOutlet weak var gpio13_out: NSButtonCell!
    @IBOutlet weak var gpio14_out: NSButtonCell!
    @IBOutlet weak var gpio15_out: NSButtonCell!
    @IBOutlet weak var gpio16_out: NSButtonCell!
    
    @IBOutlet weak var gpio1_data: NSTextFieldCell!
    @IBOutlet weak var gpio2_data: NSTextFieldCell!
    @IBOutlet weak var gpio3_data: NSTextFieldCell!
    @IBOutlet weak var gpio4_data: NSTextFieldCell!
    @IBOutlet weak var gpio5_data: NSTextFieldCell!
    @IBOutlet weak var gpio6_data: NSTextFieldCell!
    @IBOutlet weak var gpio7_data: NSTextFieldCell!
    @IBOutlet weak var gpio8_data: NSTextFieldCell!
    @IBOutlet weak var gpio9_data: NSTextFieldCell!
    @IBOutlet weak var gpio10_data: NSTextFieldCell!
    @IBOutlet weak var gpio11_data: NSTextFieldCell!
    @IBOutlet weak var gpio12_data: NSTextFieldCell!
    @IBOutlet weak var gpio13_data: NSTextFieldCell!
    @IBOutlet weak var gpio14_data: NSTextFieldCell!
    @IBOutlet weak var gpio15_data: NSTextFieldCell!
    @IBOutlet weak var gpio16_data: NSTextFieldCell!
    
    var output_length = 0
    
    @IBAction func load_file(_ sender: NSButtonCell) {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                
                guard let filepath =  openPanel.url?.path else {
                    return
                }
                
                let file_reader = StreamReader(path:filepath)
                var line = file_reader?.nextLine()
                
                
                while 1 == 1
                {
                    line = file_reader?.nextLine()
                    
                    if line == nil
                    {
                        break
                    }
                    
                    let items = line?.components(separatedBy: ",")
                    let item1 = items?[0]


                    let ID = item1!


                    switch ID {
                        case "GPIO1":
                            let item2 = items?[1]
                            let item3 = items?[2]
                            let item4 = items?[3]
                            let item5 = items?[4]
                        
                            let direction = item2!
                            let clock = item3!
                            let trigger = item4!
                            var data = item5!
                        
                        self.pin_state[0] = direction
                        if direction == "1"
                        {
                           self.gpio1_in.state = 1
                           self.gpio1_out.state = 0
                            
                        }else
                        {
                            self.gpio1_in.state = 0
                            self.gpio1_out.state = 1
                        }
                        
                            self.gpio1_data.title = data[0 ..< 10]
                            data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                            if data[0] == "b" {
                                data.remove(at: data.startIndex)
                            }
                            self.output_length = data.characters.count
                            var string = ""
                            
                            if self.output_length <= 100
                            {
                                
                                string = "GL00" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                                
                                string += self.terminal_char
                                string +=  "\r\n"

                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }else
                            {
                                
                                
                                let re_load_time = (self.output_length - self.output_length % 100) / 100
                                
                                string = "GL00" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                                string += self.terminal_char

                                string +=  "\r\n"

                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                                for i in 1 ..< re_load_time + 1 {
                                    
                                    let index_left = i * 100
                                    var index_right = i * 100 + 100
                                    if index_right > (self.output_length + 1)
                                    {
                                        index_right = self.output_length + 1
                                    }
                                    
                                    string = "GLC" + data[index_left ..< index_right]
                                    
                                    string += self.terminal_char
                                    string +=  "\r\n"

                                    
                                    if let data = string.data(using: String.Encoding.utf8) {
                                        self.serialPort?.send(data)
                                    }
                                    usleep(useconds_t(self.sleeptime))
                                    
                                }
                                
                            }
                            
                            
                            string = "GPIO01,Loaded " + String(self.output_length) + " Bits\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true

                        
                        
                        case "GPIO2":
                            
                            let item2 = items?[1]
                            let item3 = items?[2]
                            let item4 = items?[3]
                            let item5 = items?[4]
                            
                            let direction = item2!
                            let clock = item3!
                            let trigger = item4!
                            var data = item5!
                            
                            self.pin_state[1] = direction

                            if direction == "1"
                            {
                                self.gpio2_in.state = 1
                                self.gpio2_out.state = 0
                                
                            }else
                            {
                                self.gpio2_in.state = 0
                                self.gpio2_out.state = 1
                            }
                            
                            self.gpio2_data.title = data[0 ..< 10]
                            data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                            if data[0] == "b" {
                                data.remove(at: data.startIndex)
                            }
                            self.output_length = data.characters.count
                            var string = ""
                            
                            if self.output_length <= 100
                            {
                                
                                string = "GL01" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                                string += self.terminal_char
                                string +=  "\r\n"
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }else
                            {
                                
                                
                                let re_load_time = (self.output_length - self.output_length % 100) / 100
                                
                                string = "GL01" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                                for i in 1 ..< re_load_time + 1 {
                                    
                                    let index_left = i * 100
                                    var index_right = i * 100 + 100
                                    if index_right > (self.output_length + 1)
                                    {
                                        index_right = self.output_length + 1
                                    }
                                    
                                    string = "GLC" + data[index_left ..< index_right]
                                    string += self.terminal_char
                                    string +=  "\r\n"
                                    
                                    if let data = string.data(using: String.Encoding.utf8) {
                                        self.serialPort?.send(data)
                                    }
                                    usleep(useconds_t(self.sleeptime))
                                    
                                }
                                
                            }
                            
                            
                            string = "GPIO02,Loaded " + String(self.output_length) + " Bits\n"
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                        
                    case "GPIO3":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        
                        self.pin_state[2] = direction

                        if direction == "1"
                        {
                            self.gpio3_in.state = 1
                            self.gpio3_out.state = 0
                            
                        }else
                        {
                            self.gpio3_in.state = 0
                            self.gpio3_out.state = 1
                        }
                        
                        self.gpio3_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL02" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL02" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO03,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                    case "GPIO4":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        
                        self.pin_state[3] = direction

                        if direction == "1"
                        {
                            self.gpio4_in.state = 1
                            self.gpio4_out.state = 0
                            
                        }else
                        {
                            self.gpio4_in.state = 0
                            self.gpio4_out.state = 1
                        }
                        
                        self.gpio4_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL03" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL03" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        string = "GPIO04,Loaded " + String(self.output_length) + " Bits\n"
                        
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO5":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        if direction == "1"
                        {
                            self.gpio5_in.state = 1
                            self.gpio5_out.state = 0
                            
                        }else
                        {
                            self.gpio5_in.state = 0
                            self.gpio5_out.state = 1
                        }
                        
                        self.gpio5_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL04" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL04" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO05,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                       
                        
                    case "GPIO6":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        
                        self.pin_state[5] = direction

                        if direction == "1"
                        {
                            self.gpio6_in.state = 1
                            self.gpio6_out.state = 0
                            
                        }else
                        {
                            self.gpio6_in.state = 0
                            self.gpio6_out.state = 1
                        }
                        
                        self.gpio6_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        
                        
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL05" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL05" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO06,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO7":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[6] = direction

                        if direction == "1"
                        {
                            self.gpio7_in.state = 1
                            self.gpio7_out.state = 0
                            
                        }else
                        {
                            self.gpio7_in.state = 0
                            self.gpio7_out.state = 1
                        }
                        
                        self.gpio7_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL06" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL06" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO07,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO8":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        
                        self.pin_state[7] = direction

                        if direction == "1"
                        {
                            self.gpio8_in.state = 1
                            self.gpio8_out.state = 0
                            
                        }else
                        {
                            self.gpio8_in.state = 0
                            self.gpio8_out.state = 1
                        }
                        
                        self.gpio8_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL07" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL07" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO08,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO9":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[8] = direction

                        if direction == "1"
                        {
                            self.gpio9_in.state = 1
                            self.gpio9_out.state = 0
                            
                        }else
                        {
                            self.gpio9_in.state = 0
                            self.gpio9_out.state = 1
                        }
                        
                        self.gpio9_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL08" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL08" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string +=  "\r\n"

                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO09,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                    case "GPIO10":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[9] = direction

                        if direction == "1"
                        {
                            self.gpio10_in.state = 1
                            self.gpio10_out.state = 0
                            
                        }else
                        {
                            self.gpio10_in.state = 0
                            self.gpio10_out.state = 1
                        }
                        
                        self.gpio10_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL09" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL09" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO10,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
  
                        
                    case "GPIO11":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[10] = direction

                        if direction == "1"
                        {
                            self.gpio11_in.state = 1
                            self.gpio11_out.state = 0
                            
                        }else
                        {
                            self.gpio11_in.state = 0
                            self.gpio11_out.state = 1
                        }
                        
                        self.gpio11_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL10" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL10" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO11,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO12":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[11] = direction

                        if direction == "1"
                        {
                            self.gpio12_in.state = 1
                            self.gpio12_out.state = 0
                            
                        }else
                        {
                            self.gpio12_in.state = 0
                            self.gpio12_out.state = 1
                        }
                        
                        self.gpio12_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL11" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL11" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO12,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                        
                    case "GPIO13":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[12] = direction

                        if direction == "1"
                        {
                            self.gpio13_in.state = 1
                            self.gpio13_out.state = 0
                            
                        }else
                        {
                            self.gpio13_in.state = 0
                            self.gpio13_out.state = 1
                        }
                        
                        self.gpio13_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL12" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL12" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO13,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                        
                    case "GPIO14":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[13] = direction

                        if direction == "1"
                        {
                            self.gpio14_in.state = 1
                            self.gpio14_out.state = 0
                            
                        }else
                        {
                            self.gpio14_in.state = 0
                            self.gpio14_out.state = 1
                        }
                        
                        self.gpio14_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL13" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL13" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO14,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO15":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!
                        
                        self.pin_state[14] = direction

                        if direction == "1"
                        {
                            self.gpio15_in.state = 1
                            self.gpio15_out.state = 0
                            
                        }else
                        {
                            self.gpio15_in.state = 0
                            self.gpio15_out.state = 1
                        }
                        
                        self.gpio15_data.title = data[0 ..< 10]
                        data = String(data.characters.filter { !" \n\t\r".characters.contains($0) })
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {
                            
                            string = "GL14" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                        }else
                        {
                            
                            
                            let re_load_time = (self.output_length - self.output_length % 100) / 100
                            
                            string = "GL14" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {
                                
                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }
                        
                        
                        string = "GPIO15,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    case "GPIO16":
                        
                        let item2 = items?[1]
                        let item3 = items?[2]
                        let item4 = items?[3]
                        let item5 = items?[4]
                        
                        let direction = item2!
                        let clock = item3!
                        let trigger = item4!
                        var data = item5!

                        
                        self.pin_state[15] = direction

                        if direction == "1"
                        {
                            self.gpio16_in.state = 1
                            self.gpio16_out.state = 0
                            
                        }else
                        {
                            self.gpio16_in.state = 0
                            self.gpio16_out.state = 1
                        }
                        
                        self.gpio16_data.title = data[0 ..< 10]
                        
                        if data[0] == "b" {
                            data.remove(at: data.startIndex)
                        }
                        self.output_length = data.characters.count
                        var string = ""
                        
                        if self.output_length <= 100
                        {

                            string = "GL15" + direction + clock + trigger + "01" + data[0 ..< self.output_length+1]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                           self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                            self.receivedDataTextView.needsDisplay = true
                            
                            
                            
                        }else
                        {
                            

                            let re_load_time = (self.output_length - self.output_length % 100) / 100

                            string = "GL15" + direction + clock + trigger + String(format:"%02d",re_load_time+1) + data[0 ..< 100]
                            string += self.terminal_char
                            string +=  "\r\n"
                            
                            if let data = string.data(using: String.Encoding.utf8) {
                                self.serialPort?.send(data)
                            }
                            usleep(useconds_t(self.sleeptime))
                            
                            for i in 1 ..< re_load_time + 1 {

                                let index_left = i * 100
                                var index_right = i * 100 + 100
                                if index_right > (self.output_length + 1)
                                {
                                    index_right = self.output_length + 1
                                }
                                
                                string = "GLC" + data[index_left ..< index_right]
                                string += self.terminal_char
                                string +=  "\r\n"
                                
                                if let data = string.data(using: String.Encoding.utf8) {
                                    self.serialPort?.send(data)
                                }
                                usleep(useconds_t(self.sleeptime))
                                
                            }
                            
                        }


                        string = "GPIO16,Loaded " + String(self.output_length) + " Bits\n"
                        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
                        self.receivedDataTextView.needsDisplay = true
                        
                        
                    default:
                            print("Some other character")
                    }
                    
                    //load_extra_packets(data,ser)
                    
                    //load the data ?
                }
                
                //load_complete()
                
            }
        }
        
    }
    
    
    @IBOutlet weak var input_cycles: NSTextFieldCell!
    
    var frequency_record = 0
    var input_cycles_record = 0
    
    @IBOutlet weak var frequency: NSTextFieldCell!

    @IBAction func set_input_cycles(_ sender: AnyObject?) {
        
        var string = ""
        
        frequency_record = input_cycles.integerValue
        
        //Formating the Message
        string += "GC"  //DAC Identified
        string += String(format:"%04d",frequency_record)
        
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(self.sleeptime))

    }

    @IBAction func set_frequency(_ sender: AnyObject?) {
        //Set Frequency
        var string = ""
        
        frequency_record = frequency.integerValue
        
        //Formating the Message
        string += "GF"  //DAC Identified
        string += String(format:"%08d",frequency_record)

        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(self.sleeptime))

    }
    
    @IBAction func Begin(_ sender: Any) {
        
        self.set_frequency(nil)
        self.set_input_cycles(nil)
        
        var string = ""
        //Formating the Message
        string += "GB"  //DAC Identified
        string +=  "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(self.sleeptime))

    }
    


    
    @IBAction func save_input_to_file(_ sender: Any) {
        
        
        for i in 0 ..< 16 {
            
            if self.pin_state[i] == "1"
            {
                self.buffer[i] = ""

                var string = ""
            
                string = "GR"
                string += self.terminal_char
                string +=  "\r\n"
                
            usleep(useconds_t(self.sleeptime))
            }
        }
        
        usleep(useconds_t(self.sleeptime))

        let directoryName = "Digital_Input_folder"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        
        let dirURL = documentsURL?.appendingPathComponent(directoryName)
        
        guard let dirpath = dirURL?.path else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: dirpath) {
            try! FileManager.default.createDirectory(atPath: dirpath, withIntermediateDirectories: false, attributes: nil)
        } else {
        }
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date as Date)
        
        let month = calendar.component(.month, from: date as Date)
        let day = calendar.component(.day, from: date as Date)
        
        let hour = calendar.component(.hour, from: date as Date)
        let minutes = calendar.component(.minute, from: date as Date)
        
        
        var filename = year.description + "_"
        filename = filename + month.description + "_"
        filename = filename + day.description + "_"
        filename = filename + hour.description + "_"
        filename = filename + minutes.description + "_"
        filename = filename + "_Digital_Input_Buffer.csv"
        
        
        let fileURL = dirURL?.appendingPathComponent(filename)
        
        
        var string = "GPIO_ID,data,\n"
        
        for i in 0 ..< 16 {
            
            string = string + "GPIO" + String(i + 1) + ","
            string = string + buffer[i] + ",\n"

        }

        try! string.write(to: fileURL!, atomically: true, encoding: String.Encoding.macOSRoman)
        
        
        string = "Digital Input File saved to" + (fileURL?.path)!
        
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        
    
    }
    
    @IBOutlet weak var RF: NSButtonCell!
    
    @IBOutlet weak var FR: NSButtonCell!
    
    @IBOutlet weak var spi_bitrate: NSTextFieldCell!
    @IBOutlet weak var sample: NSButtonCell!
    @IBOutlet weak var setup: NSButtonCell!
    @IBOutlet weak var MSB: NSButtonCell!
    @IBOutlet weak var LSB: NSButtonCell!
    @IBOutlet weak var spi_data: NSTextFieldCell!
    @IBAction func spi_send(_ sender: Any) {
        
       
        
        
        var string = ""
        //Formating the Message
        string = "GSM"
        string += String(format:"%06d",spi_bitrate.integerValue)
        string += String(format:"%01d",MSB.state)
        string += String(format:"%01d",sample.state)
        string += String(format:"%01d",RF.state)
        string +=  "\r\n"
        
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(self.sleeptime))
        
        
        string = "GSD" + spi_data.title
        string +=  "\0\r\n"
    
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        //Sets the text
        if let data = string.data(using: String.Encoding.utf8) {
            self.serialPort?.send(data)
        }
        usleep(useconds_t(self.sleeptime))
        
        string =  "SPI Master Sent :" + spi_data.title + "\r\n"
        
        //Log this message to the window
        self.receivedDataTextView.textStorage?.mutableString.append(string as String)
        self.receivedDataTextView.needsDisplay = true
        
        
    }
    
    
    
    

}

I'm building a :
** Persistent Data Structure with explicit invariants ** 

1️⃣ What is a “binary layout table” (with examples)
A binary layout table is just you answering:
“At byte X, what lives there, how big is it, and what does it mean?”

7️⃣ The key takeaway (this should settle your confusion)
A file format is not “about data types”.
It is about layout + invariants + access patterns.
Once you grasp that, the rest becomes engineering, not mystery.

--------------------------------- DAY 2. 
So here is my understanding so far. The file will have Header Size size of bytes in the start. While reading, the Header Size field will indicate that "Hey, starting from 0th byte, Header Size bytes are the headers, the metadata". 
The Header contains information of where (Offset) you'll 'start to find' Tables(Record Table offset) and the actual string data(String Blob Offset). 
Each record in the Records table contains the starting location of data(String Offset) of the respective string data. 
All the names in the format layout is just for the devs to work with. The Reader and Writer will be designed as such. 

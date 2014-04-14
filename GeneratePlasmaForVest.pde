import java.io.File;

PrintWriter myFile;
String fileName = "C:\\users\\Computer\\Desktop\\FullColorPlasmaMorph20.led";

int LEDCOUNT = 470;
int generateFrames = 50000;
byte[] renderedDataFile = new byte[LEDCOUNT*3*generateFrames];

int frameNo = 0;
int ledFactor = 4;
float shade;
int size = 13; //lower=smaller
float sinShadePiRed, sinShadePiGreen, sinShadePiBlue;
int r,g,b;
float minShade = -1.3;
float maxShade =1.3;
int brightness = 100;

float movement;
float movementFactor = 0.053;

float cx, cy;
int worldWidth = 40;
int worldHeight = 20;
float dist; 

boolean dev = false;
boolean display = true;
boolean realtimeDisplay = false; //true is smaller

LED[] leds = new LED[LEDCOUNT];

void setup() 
{
  //frameRate(25);
  size(200 * ledFactor, 120 * ledFactor);
  background(0);
  if(realtimeDisplay) loadPixels();
 
  PopulateLedArray();
  
  println("Starting");
}

void draw() {
   background(0);
  if( frameNo<generateFrames)
  {
    println(frameNo);
    Plasma();
    frameNo++;
    text(10,10,frameRate);
  }
  else
  {
    DeletePreviousSDFile();
    saveBytes(fileName, renderedDataFile);
    print("File Created - "); 
    println(millis());
    exit();
  }
  
}



void DeletePreviousSDFile()
{
  File f = new File(fileName);
  
  if (f.exists()) 
  {
    f.delete();
    println("Deleted Previous File");
  }
}

void Plasma()
{

  for(int i = 0; i<LEDCOUNT; i++)
  {
    //get the xy co-ordinates and spread out by factor.
    LED c = new LED(leds[i].x, leds[i].y);
    c.x*=ledFactor;
    c.y*=ledFactor;
    
    if(dev)
     {
      print("led="); print(i);
      print(" sv="); print(SinVerticle(c.x,c.y,size));
      print(" sr="); print(SinRotating(c.x,c.y,size));
      print(" sc="); print(SinCircle(c.x,c.y,size));
     }
     
     //get the three sin waves and combine the results
    shade = (
               SinVerticle(c.x,c.y,size) //42ms
              +SinRotating(c.x,c.y,size)  //91ms
              +SinCircle(c.x,c.y, size)//120ms
            )/3; 
             //250ms
             
    if(dev) {print(" shade="); print(shade);}
    
    //Optimization Mathematics
    sinShadePiRed = sin(shade*PI); //21ms
    sinShadePiGreen = sin(shade*PI+2); //36ms
    sinShadePiBlue = sin(shade*PI+4); //42ms
    
    SelfCorrectMapping();
    
    if(dev)
    {
      print(" sinShadePiRed="); print(sinShadePiRed);
      print(" sinShadePiBlue="); print(sinShadePiRed);
    }
     
    r = (int)map( sinShadePiRed, minShade, maxShade, 0, brightness);//2ms
    //g = (int)map( sinShadePiGreen, minShade, maxShade, 0, brightness);//2ms
    //b = (int)map( sinShadePiBlue, minShade, maxShade, 0, brightness);//2ms
     
    if(dev)
    {
      print(" r="); print(r);
      print(" b="); print(b);
    }
     
    //r = map( sin(shade*PI)*100, minShade, maxShade, 0, brightness);
    g = (int)map( sin(shade*PI+2*(sin(movement)/2)), minShade, maxShade, 0, brightness);
    b = (int)map( sin(shade*PI+4*PI*sin(movement/7)), minShade, maxShade, 0, brightness);
     
    WriteLedDataToFileBuffer(r,g,b,i); 
    if(realtimeDisplay) {DisplayPixel(r,g,b,c);}
    else {DisplayPixel2(r,g,b,c);}
    
    }
  
    movement+=movementFactor;
    //strip.show();
    
    
    if(display)
    {
      del(40);
      updatePixels();
      println(millis());
    }
   
}

float SinVerticle(float x, float y, float s)
{
  return sin(x / s + movement);
}
 
float SinRotating(float x, float y, float s)
{
  return sin(  (x * sin(movement/9 ) + y * cos(movement/6) )  /(size*.6)) ;
}
 
float SinCircle(float x, float y, float s)
{
  cx = worldWidth * sin(movement/5)*ledFactor;
  cy = worldHeight * cos(movement/10)*ledFactor;
  //cx = worldWidth / 2.5 * ledFactor;
  //cy = worldHeight / 2.5 * ledFactor;
  
  dist = sqrt(sq(cy-y) + sq(cx-x));
  return sin((dist/s ) + movement);
}

void DisplayPixel(int r, int g, int b, LED c)
{
    //position the pixels so it looks good on the screen
    int pixelidx = ((width*height-5)-width*3) - (c.x+(c.y*width));
   
    int col = color(r*5,g*5,b*5);
    
    pixels[pixelidx] = col;
    pixels[pixelidx-1] = col;
    pixels[pixelidx-1+width] = col;
    pixels[pixelidx+width] = col;
}

void DisplayPixel2(int r, int g, int b, LED c)
{
    //position the pixels so it looks good on the screen
    int x = (c.x * 6)+20;
    int y = height - (c.y * 6)-20;
    
    int col = color(r*10,g*10,b*10);  //time ten to make it visiable on the screen
    fill(color(r*3,g*3,b*3));
    ellipse(x,y,20,20);
}


void WriteLedDataToFileBuffer(int r,  int  g,  int  b, int idx)
{ 
  int loc = frameNo*LEDCOUNT*3;
  renderedDataFile[loc+idx*3] = (byte)r;
  renderedDataFile[loc+idx*3+1] = (byte)g;
  renderedDataFile[loc+idx*3+2] = (byte)b;

  if(dev)
  {
    print(" idx"); print(idx);
    print(" br=");print(renderedDataFile[loc+idx*3]);
    print(" bg=");print(renderedDataFile[loc+idx*3+1]);
    print(" bb=");println(renderedDataFile[loc+idx*3+2]);
  }
}

void del(int wait)
{
  long start = millis();
  while(start+wait>millis()){}
}

void SelfCorrectMapping()
{
  // tune mapping values to ensure maximum led resolution
    if(sinShadePiRed < minShade) minShade = sinShadePiRed;
    if(sinShadePiRed > maxShade) maxShade = sinShadePiRed;
    if(sinShadePiGreen < minShade) minShade = sinShadePiGreen;
    if(sinShadePiGreen > maxShade) maxShade = sinShadePiGreen;
    if(sinShadePiBlue < minShade) minShade = sinShadePiBlue;
    if(sinShadePiBlue > maxShade) maxShade = sinShadePiBlue;
}

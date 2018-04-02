/*---------------------------------------------------------------
Created by: Leonardo Merza
Version: 1.0
 
This class will track skeletons of users and draw them
----------------------------------------------------------------*/
 
/*---------------------------------------------------------------
Imports
----------------------------------------------------------------*/
// import kinect library
import SimpleOpenNI.*;
 
/*---------------------------------------------------------------
Variables
----------------------------------------------------------------*/
// create kinect object
SimpleOpenNI  kinect;
// image storage from kinect
PImage kinectDepth;
// int of each user being  tracked
int[] userID;
// user colors
color[] userColor = new color[]{ color(255,0,0), color(0,255,0), color(0,0,255),
                                 color(255,255,0), color(255,0,255), color(0,255,255)};
 
// postion of head to draw circle
PVector headPosition = new PVector();
PVector leftHandPosition = new PVector();
PVector[] leftHandPositions = new PVector[10000];

// turn headPosition into scalar form
float distanceScalar;
// diameter of head drawn in pixels
float headSize = 200;
 
// threshold of level of confidence
float confidenceLevel = 0.5;
// the current confidence level that the kinect is tracking
float confidence;
// vector of tracked head for confidence checking
PVector confidenceVector = new PVector();
 
/*---------------------------------------------------------------
Starts new kinect object and enables skeleton tracking.
Draws window
----------------------------------------------------------------*/
void setup_tracking()
{
  // start a new kinect object
  kinect = new SimpleOpenNI(this);
 
  // enable depth sensor
  kinect.enableDepth();
 
  // enable skeleton generation for all joints
  kinect.enableUser();
 
  // draw thickness of drawer
  strokeWeight(3);
  // smooth out drawing
  smooth();
 

} // void setup()
 
/*---------------------------------------------------------------
Updates Kinect. Gets users tracking and draws skeleton and
head if confidence of tracking is above threshold
----------------------------------------------------------------*/
void draw(){
  // update the camera
  kinect.update();
  // get Kinect data
  kinectDepth = kinect.depthImage();
  // draw depth image at coordinates (0,0)
  image(kinectDepth,0,0); 
 
   // get all user IDs of tracked users
  userID = kinect.getUsers();
 
  // loop through each user to see if tracking
  for(int i=0;i<userID.length;i++)
  {
    // if Kinect is tracking certain user then get joint vectors
    if(kinect.isTrackingSkeleton(userID[i]))
    {
      // get confidence level that Kinect is tracking head
      confidence = kinect.getJointPositionSkeleton(userID[i],
                          SimpleOpenNI.SKEL_HEAD,confidenceVector);
 
      // if confidence of tracking is beyond threshold, then track user
      if(confidence > confidenceLevel)
      {
        // change draw color based on hand id#
        stroke(userColor[(i)]);
        // fill the ellipse with the same color
        fill(userColor[(i)]);
        // draw the rest of the body
        drawSkeleton(userID[i]);
 
      } //if(confidence > confidenceLevel)
    } //if(kinect.isTrackingSkeleton(userID[i]))
  } //for(int i=0;i<userID.length;i++)
} // void draw()
 
/*---------------------------------------------------------------
Draw the skeleton of a tracked user.  Input is userID
----------------------------------------------------------------*/
float maxLeftHandY = 0;
float minLeftHandY = 100000000;
float MAXY = 480;
float MINY = -480;
PVector leftKneePosition = new PVector();
long i = 0;
void drawSkeleton(int userId){
  i += 1;
   // get 3D position of head
  kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD,headPosition);
  // convert real world point to projective space
  kinect.convertRealWorldToProjective(headPosition,headPosition);
  // create a distance scalar related to the depth in z dimension
  distanceScalar = (525/headPosition.z);
  // draw the circle at the position of the head with the head size scaled by the distance scalar
  ellipse(headPosition.x,headPosition.y, distanceScalar*headSize,distanceScalar*headSize);
  
  kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, leftHandPosition);
  kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_KNEE, leftKneePosition);
  
  maxLeftHandY = max(leftHandPosition.y, maxLeftHandY);
  minLeftHandY = min(leftHandPosition.y, minLeftHandY);
  
  MAXY = headPosition.y;
  MINY = leftKneePosition.y;
  if(i % 10 == 0) {
      println("min " + MINY + "max " + MAXY, "hand", leftHandPosition.y);

      //println("min " + minLeftHandY + "max " + maxLeftHandY);
      float scaledY = (leftHandPosition.y - MINY) / (MAXY - MINY) * 255; 
      int bri = ceil(scaledY); 
      bri = min(bri, 255);
      bri = max(bri, 1);
      String message = "bri=" + bri + "\n";
      println("Sending: " + message);
      myClient.write(message);
  }
  
  ////leftHandPositions.
  //println("leftHandPosition.x " + leftHandPosition.x);
  // println("leftHandPosition.y " + leftHandPosition.y);
  // println("leftHandPosition.z " + leftHandPosition.z);
   
 
  //draw limb from head to neck
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
  //draw limb from neck to left shoulder
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  //draw limb from left shoulde to left elbow
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  //draw limb from left elbow to left hand
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);
  //draw limb from neck to right shoulder
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  //draw limb from right shoulder to right elbow
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  //draw limb from right elbow to right hand
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);
 //draw limb from left shoulder to torso
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  //draw limb from right shoulder to torso
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  //draw limb from torso to left hip
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  //draw limb from left hip to left knee
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP,  SimpleOpenNI.SKEL_LEFT_KNEE);
  //draw limb from left knee to left foot
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);
  //draw limb from torse to right hip
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  //draw limb from right hip to right knee
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  //draw limb from right kneee to right foot
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
} // void drawSkeleton(int userId)
 
/*---------------------------------------------------------------
When a new user is found, print new user detected along with
userID and start pose detection.  Input is userID
----------------------------------------------------------------*/
void onNewUser(SimpleOpenNI curContext, int userId){
  println("New User Detected - userId: " + userId);
  // start tracking of user id
  curContext.startTrackingSkeleton(userId);
} //void onNewUser(SimpleOpenNI curContext, int userId)
 
/*---------------------------------------------------------------
Print when user is lost. Input is int userId of user lost
----------------------------------------------------------------*/
void onLostUser(SimpleOpenNI curContext, int userId){
  // print user lost and user id
  println("User Lost - userId: " + userId);
} //void onLostUser(SimpleOpenNI curContext, int userId)
 
/*---------------------------------------------------------------
Called when a user is tracked.
----------------------------------------------------------------*/
void onVisibleUser(SimpleOpenNI curContext, int userId){
} //void onVisibleUser(SimpleOpenNI curContext, int userId)


 //<>//
import processing.net.*;
Client myClient = new Client(this, "127.0.0.1", 8888);

public void setup_hue() 
{
 //size(200, 200); 
 myClient = new Client(this, "127.0.0.1", 8888);
 myClient.write("id=1,on=0,bri=1,hue=15342");
 //myClient.write("HO");
}

public void setup() {
    // create a window the size of the depth information
  size(640, 480);
  //setup_hue();
  setup_tracking();
}

% Here is the order of joints returned by Kinect for Windows
%     HipCenter = 1;
%     Spine = 2;
%     ShoulderCenter = 3;
%     Head = 4;
%     ShoulderLeft = 5;
%     ElbowLeft = 6;
%     WristLeft = 7;
%     HandLeft = 8;
%     ShoulderRight = 9;
%     ElbowRight = 10;
%     WristRight = 11;
%     HandRight = 12;
%     HipLeft = 13;
%     KneeLeft = 14;
%     AnkleLeft = 15;
%     FootLeft = 16; 
%     HipRight = 17;
%     KneeRight = 18;
%     AnkleRight = 19;
%     FotoRight = 20;         

global CONNECTION_MAP
CONNECTION_MAP = [[1 2];
                  [2 3];
                  [3 4];
                  [3 5];
                  [5 6];
                  [6 7];
                  [7 8];
                  [3 9];
                  [9 10];
                  [10 11];
                  [11 12];
                  [1 17];
                  [17 18];
                  [18 19];
                  [19 20];
                  [1 13];
                  [13 14];
                  [14 15];
                  [15 16]];
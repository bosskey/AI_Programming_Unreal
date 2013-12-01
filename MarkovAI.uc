class MarkovAI extends UDKBot;
var Pawn Player1;
var Pawn Target;
var Vector NavGoalLocation;
var Vector NextLocationToGoal;
var array<float> mRow1;
var array<float> mRow2;
var array<float> prevProb;
var array<float> curProb;
//var array<array<float>> matrix;
var int Goal;
var bool curGoal;
var float Discont;

auto state Wander
{
	event SeePlayer(Pawn SeenPlayer)
	{
	    Target = SeenPlayer;
	    //if(Pawn.Health>MaxHealth)
            //GotoState('Seek');

        }
	function GetNextRandomLocation()
	{
		//class'NavMeshGoal_At'.static.AtLocation(NavigationHandle,Target.Location);
		class'NavMeshGoal_Random'.static.FindRandom(NavigationHandle, 200);
		class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle,NextLocationToGoal);
		NavigationHandle.FindPath();


		NavGoalLocation=NavigationHandle.PathCache_GetGoalPoint();
		//NavGoalLocation=Target.Location;//only if following target


		NavigationHandle.SetFinalDestination(NavGoalLocation);
		if(NavigationHandle.PointReachable(NavGoalLocation))
			NextLocationToGoal=NavGoalLocation;
		else
			NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);

	}
	function SetNextLocationInPath()
	{

		NavigationHandle.GetNextMoveLocation(NextLocationToGoal,50);//checkme

	}
	   function BeginState (name PreviousStateName){
		NavGoalLocation=Pawn.Location;
	   }
	Begin:
	   WaitForLanding();
	  // Worldinfo.Game.Broadcast(self, "begin");
	   if(Pawn.ReachedPoint(NavGoalLocation, None)){
		GetNextRandomLocation();
		 Worldinfo.Game.Broadcast(self, "none");
	   }
	   else{
		GetNextRandomLocation();//newly added
		MoveTo(NextLocationToGoal);
		SetNextLocationInPath();
	//	 Worldinfo.Game.Broadcast(self, "next");
	   }
	DoneWander:
	Probability();

	CheckGoals();
	Discontentment();
    Worldinfo.Game.Broadcast(self, "discontent:"@ Discont);
	if(CheckGoals()==true){
	   if(curGoal)
	   Action();

       } else {
	   KillBot();
	}

	   Sleep(1.0);
	  // Worldinfo.Game.Broadcast(self, "done");
	   goto('Begin');


}
function bool CheckGoals(){
         if(Goal==0){
         	curGoal=false;
         	return false;
         } else {
         	return true;
         }
}
function Discontentment(){
         Discont=Goal^2;
}

function KillBot(){
         Pawn.Suicide();
}

function Action(){
         Goal=Goal-2;
         Worldinfo.Game.Broadcast(self, Goal);
}

function Probability(){
         curProb[0]=(prevProb[0]*mRow1[0])+(prevProb[1]*mRow1[1]);
         curProb[1]=(prevProb[0]*mRow2[0])+(prevProb[1]*mRow2[1]);
         prevProb=curProb;
         Worldinfo.Game.Broadcast(self, "Prob[0]"@ curProb[0]);
         Worldinfo.Game.Broadcast(self, "Prob[1]"@ curProb[1]);
}

DefaultProperties
{

/*
matrix[0][0]
matrix[0][1]
matrix[1][0]
matrix[1][1]  */
curGoal=true
Goal=4
Discont=16
mRow1[0]=0.9f
mRow1[1]=0.5f
mRow2[0]=0.1f
mRow2[1]=0.5f
prevProb[0]=1.0f
prevProb[1]=0.0f

}

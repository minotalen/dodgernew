## levels
every song is its own small ecosystem
with its own obstacles, color scheme and duration
every song has a set duration, during which dodger goes through his cycle of reincarnations
(next starting score = last score*rate, rate gradually increasing)
after the song is ended, the scores of each life are graphed and a new starting score modifier is calculated
also the highest score modifier for this level is updated
the next time this song is played dodger starts with (score modifier + highest score modifier)/2 so even the starting score fluctuates
if a song is not played to the end, it can be quit to calculate the score modifier from the current scores (end the run prematurely). if the run is not finished or quit, the score modifier gets set to 0!

#### level design
maybe make every level have a different shader
group the enemy types and make

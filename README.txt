This code is meant purely as research code, and has very minor visualization dependencies (e.g. drawing a vertical line) that aren't included in this repo. Sorry. If for some reason you actually need to run this code, removing or recreating problematic function calls shouldn't break anything.

Implements an algorithm for analyzing audio data for pairs of similar regions of time.
1. A sliding mean square difference, normalized by overlap length and average power level, is used for course searching.
2. Mean square difference between spectrograms with rectangular windowing is used for more fine tuning.
3. Sliding mean square difference is used again for even finer tuning once a similar region has been located quite precisely.

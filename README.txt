This is research code, and is NOT INTENDED FOR OUTSIDE USE.

Implements an algorithm for analyzing audio data for pairs of similar regions of time.
1. A sliding mean square difference, normalized by overlap length and average power level, is used for course searching.
2. Mean square difference between spectrograms with rectangular windowing is used for more fine tuning.
3. Sliding mean square difference is used again for even finer tuning once a similar region has been located quite precisely.
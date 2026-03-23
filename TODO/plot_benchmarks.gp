#!/usr/bin/env gnuplot
# Benchmark plots: input_bytes vs timing/size metrics.
# Run from the same directory as benchmarks.csv:
#   gnuplot plot_benchmarks.gp
#
# Produces: exec_time.png  prove_time.png  verify_time.png
#           proof_size.png  witness_size.png

DATA = 'benchmarks.csv'

# Pre-filter with awk so each series is contiguous — no gaps to break lines.
# Columns in CSV: 1=benchmark 2=hash_fn 3=input_bytes 4=repetitions
#                 5=exec_time_s 6=prove_time_s 7=verify_time_s
#                 8=proof_size_bytes 9=witness_size_bytes
AWK = "< awk -F, '"

# Build a filtered-pipe string: AWK_SERIES(col_match, xcol, ycol)
# e.g. AWK_SERIES(1, 3, 5) → awk filtering $4==1, printing $3 $5
n1_exec   = AWK."NR>1 && $4==1   {print $3, $5}' ".DATA
n10_exec  = AWK."NR>1 && $4==10  {print $3, $5}' ".DATA
n100_exec = AWK."NR>1 && $4==100 {print $3, $5}' ".DATA

n1_prove   = AWK."NR>1 && $4==1   {print $3, $6}' ".DATA
n10_prove  = AWK."NR>1 && $4==10  {print $3, $6}' ".DATA
n100_prove = AWK."NR>1 && $4==100 {print $3, $6}' ".DATA

n1_verify   = AWK."NR>1 && $4==1   {print $3, $7}' ".DATA
n10_verify  = AWK."NR>1 && $4==10  {print $3, $7}' ".DATA
n100_verify = AWK."NR>1 && $4==100 {print $3, $7}' ".DATA

n1_proof   = AWK."NR>1 && $4==1   {print $3, $8}' ".DATA
n10_proof  = AWK."NR>1 && $4==10  {print $3, $8}' ".DATA
n100_proof = AWK."NR>1 && $4==100 {print $3, $8}' ".DATA

n1_wit   = AWK."NR>1 && $4==1   {print $3, $9}' ".DATA
n10_wit  = AWK."NR>1 && $4==10  {print $3, $9}' ".DATA
n100_wit = AWK."NR>1 && $4==100 {print $3, $9}' ".DATA

set terminal pngcairo size 960,640 enhanced font 'sans,13'
set style data linespoints
set grid lc rgb '#cccccc'
set key top left

set xlabel 'Input size (bytes)'
set logscale x 2
set xtics (32, 64, 128, 256, 512, 1024, 2048)
set xrange [24:2730]

# ---------------------------------------------------------------------------
# 1. Execution (witness generation) time
# ---------------------------------------------------------------------------
set output 'exec_time.png'
set title 'keccak256: Execution Time vs Input Size'
set ylabel 'Time (s)'
set logscale y
set format y '%g'

plot n1_exec   using 1:2 title 'N=1'   pt 7 lw 2, \
     n10_exec  using 1:2 title 'N=10'  pt 5 lw 2, \
     n100_exec using 1:2 title 'N=100' pt 9 lw 2

# ---------------------------------------------------------------------------
# 2. Proving time
# ---------------------------------------------------------------------------
set output 'prove_time.png'
set title 'keccak256: Proving Time vs Input Size'
set ylabel 'Time (s)'

plot n1_prove   using 1:2 title 'N=1'   pt 7 lw 2, \
     n10_prove  using 1:2 title 'N=10'  pt 5 lw 2, \
     n100_prove using 1:2 title 'N=100' pt 9 lw 2

# ---------------------------------------------------------------------------
# 3. Verifying time  (tiny variation ~20-33ms, use linear Y)
# ---------------------------------------------------------------------------
set output 'verify_time.png'
set title 'keccak256: Verifying Time vs Input Size'
set ylabel 'Time (s)'
unset logscale y
set yrange [0:*]
set format y '%g'

plot n1_verify   using 1:2 title 'N=1'   pt 7 lw 2, \
     n10_verify  using 1:2 title 'N=10'  pt 5 lw 2, \
     n100_verify using 1:2 title 'N=100' pt 9 lw 2

unset yrange

# ---------------------------------------------------------------------------
# 4. Proof size  (constant 16256 B for all — HONK property)
# ---------------------------------------------------------------------------
set output 'proof_size.png'
set title 'keccak256: Proof Size vs Input Size'
set ylabel 'Size (bytes)'
unset logscale y
set yrange [14000:18000]
set ytics ('16 256' 16256)

plot n1_proof   using 1:2 title 'N=1'   pt 7 lw 2, \
     n10_proof  using 1:2 title 'N=10'  pt 5 lw 2, \
     n100_proof using 1:2 title 'N=100' pt 9 lw 2

# ---------------------------------------------------------------------------
# 5. Witness size
# ---------------------------------------------------------------------------
set output 'witness_size.png'
set title 'keccak256: Witness Size vs Input Size'
set ylabel 'Size (bytes)'
unset yrange
set logscale y
# Explicit ticks with space-formatted thousands
set ytics ('1 000' 1e3, '10 000' 1e4, '100 000' 1e5, \
           '1 000 000' 1e6, '10 000 000' 1e7)

plot n1_wit   using 1:2 title 'N=1'   pt 7 lw 2, \
     n10_wit  using 1:2 title 'N=10'  pt 5 lw 2, \
     n100_wit using 1:2 title 'N=100' pt 9 lw 2

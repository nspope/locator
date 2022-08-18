mkdir -p out/test
for SCALE in `seq 100 50 1000`; do
  printf '
  scale <- %s
  samps <- read.table("test_sample_data.txt", header=TRUE)
  samps$sample_weight <- ifelse(!is.na(samps$x) & samps$x > 25, 1/scale, 1)
  write.table(samps, paste0("out/test/test_sample_data_weights_", scale, ".txt"), row.names=FALSE, quote=TRUE, col.names=TRUE, sep="\t")
  library(ggplot2); library(cowplot)
  ggplot(samps) + 
    geom_point(aes(x=x, y=y, size=sample_weight), alpha=0.25) +
    xlim(0,50) + ylim(0,50) +
    theme_cowplot() + theme(plot.background=element_rect(fill="white")) ->
    plt
  ggsave(paste0("out/test/test_weights_", scale, ".png"), width=10, height=8, dpi=300, units="in")
  ' $SCALE | R --slave &>/dev/null

  locator.py --vcf test_genotypes.vcf.gz \
      --sample_data out/test/test_sample_data_weights_${SCALE}.txt \
      --weight_samples tsv \
      --sample_weights out/test/test_sample_data_weights_${SCALE}.txt \
      --gpu_number 1 \
      --batch_size 128 \
      --out out/test/test_weights_$SCALE --seed 1 &>out/test/_locator_${SCALE}.log
  
  #plot predictions
  printf '
  scale <- %s
  samps <- read.csv(paste0("out/test/test_weights_", scale, "_predlocs.txt"), header=TRUE)
  library(ggplot2); library(cowplot)
  ggplot(samps) + 
    geom_point(aes(x=x, y=y), color="red", alpha=0.1) +
    geom_text(aes(x=x, y=y, label=sampleID), color="black", alpha=0.5) +
    xlim(0,50) + ylim(0,50) +
    theme_cowplot() + theme(plot.background=element_rect(fill="white")) ->
    plt
  ggsave(paste0("out/test/test_pred_", scale, ".png"), width=10, height=8, dpi=300, units="in")
  ' $SCALE | R --slave &>/dev/null

done

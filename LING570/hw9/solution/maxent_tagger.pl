#!/usr/bin/env perl

### Purpose: maxent_tagger.pl
### created on 11/11/09

use strict;

main();

1;

sub main {
  my $arg_num = scalar @ARGV;
  if($arg_num != 5){
      die "usage: $0 train_file test_file raw_thres feat_thres output_dir\n";
  }	 

  my $train_file = $ARGV[0];
  my $test_file = $ARGV[1];
  my $raw_thres = $ARGV[2];
  my $feat_thres = $ARGV[3];
  my $output_dir = $ARGV[4];

  my $cmd;
  if(!-e $output_dir){
      $cmd = "mkdir $output_dir";
      systemx($cmd);
  }

  #### step 1: create train_voc
  my $train_voc_file = "$output_dir/train_voc";
  $cmd = "cat $train_file | make_voc_from_wordtag.pl 1 0 > $train_voc_file";
  systemx($cmd);
  
  #### step 2: create train.vectors.txt
  my $train_vectors_txt = "$output_dir/train.vectors.txt";

  $cmd = "fa194.exec $train_file $train_vectors_txt $train_voc_file $raw_thres > $output_dir/fa_train.log 2>&1";
  systemx($cmd);

  my $test_vectors_txt = "$output_dir/test.vectors.txt";

  $cmd = "fa194.exec $test_file $test_vectors_txt $train_voc_file $raw_thres > $output_dir/fa_test.log 2>&1";
  systemx($cmd);

  #### step 3: choose a subset of features that appear >= n_f times
  my $kept_feats = "$output_dir/kept_feats";
  $cmd = "cat $train_vectors_txt.feat | fb194.exec $feat_thres > $kept_feats";
  systemx($cmd);

  #### step 4: get the filtered vectors
  my $final_train_txt = "$output_dir/final_train.vectors.txt";
  $cmd = "cat $train_vectors_txt | filter_feat.pl $kept_feats | fc194.exec > $final_train_txt";
  systemx($cmd);

  my $final_test_txt = "$output_dir/final_test.vectors.txt";
  $cmd = "cat $test_vectors_txt | filter_feat.pl $kept_feats | fc194.exec > $final_test_txt";
  systemx($cmd);

  #### step 5: create the binary vectors
  my $train_vectors = "$output_dir/train.vectors";
  $cmd = "info2vectors -Xmx1000m --input $final_train_txt  --output $train_vectors";
  systemx($cmd);

  my $test_vectors = "$output_dir/test.vectors";
  $cmd = "info2vectors -Xmx1000m --input $final_test_txt  --output $test_vectors --use-pipe-from $train_vectors";
  systemx($cmd);

  #### step 6: training
  my $model = "$output_dir/model";
  $cmd = "vectors2train -Xmx2000m --training-file $train_vectors --trainer MaxEnt --output-classifier $model --report train:accuracy train:confusion > $model.stdout 2>$model.stderr";
  systemx($cmd);

  #### step 7: decoding
  $cmd = "classify --testing-file $test_vectors --classifier $model --report test:accuracy test:confusion test:raw > $model\_test.stdout 2>$model\_test.stderr";
  systemx($cmd);

  print STDERR "All done. Results are under $output_dir\n";
}


sub systemx {
    my ($cmd) = @_;

    print STDERR "\n\n***************$cmd\n\n";
    system($cmd);
    if($?){
        die "$cmd failed\n";
    }else{
        print STDERR "+++++$cmd++++ succeeds\n\n\n";
    }
}

% pkg load signal
% addpath('C:\Users\micha\Desktop\jsonlab-master')
## poslat nazov suboru a sekvenciu (0,1 prizvuk)
## nacitat zvuk, podla sekvencie viem pocet slabik, hladat 

clear all
# close all

#[x, fs] = audioread('sounds/its_you.wav');   # fs = vzorkovacia frekvencia
#x = x(fix(fs*1.1):fix(fs*1.9), 1);   # fs*0.8 = po prve slovo
#yMono = sum(x, 2) / size(x, 2);

#filename = 'sounds/hello2.flac';
#filename = 'sounds/especially.ogg';
#filename = 'sounds/problem.ogg';
#filename = 'sounds/catch.ogg';
#filename = 'sounds/word.ogg';
#filename = 'sounds/its_you.wav';
#filename = 'sounds/i_know.wav';
#filename = 'sounds/im_gonna_go.wav';

sound_dict = loadjson('word_dict.json');

my_word = "aspirin";

#for [val, key] = sound_dict
#  val.file_name;
#  val.stress_seq;
#end

filename = sound_dict.(my_word).file_name;

[x, fs] = audioread (strcat("sounds/dataset1/", filename));   
[B,A] = init_subbands(fs);

#udaje ku x
M = size(x, 1);     # dlzka x
N = fix(fs*0.02);   # velkost okienka - 20ms
N2 = fix(N/2);      # stred okna
w = hanning(N);     # vektor dlzky N
step = fix(N/3);    # posun okna
# step = 15;
Nfft = 512;         # rad furierovej transf
Nfft2 = fix(Nfft/2);

subplot(5, 1, 1);
plot(x, "k");       #k = cierna
axis([1, M])        # vyrez grafu

E = []; 
S = [];
t = [];
mf = [];

K = 14;
ds_old = zeros(1, K/2);
ds_new = zeros(1, K/2);
k = 0;
wg = gausswin(K);
sub_energies = [];
maxK = fix((M-N+1) / step);

for i = 1:step:(M-N+1)
  
  xx = x(i:i+N-1, 1);
  xw = x(i:i+N-1, 1) .* w;
  t = [t;(i+N2)/fs];
  
  #spectrogram
  #[S0, nic] = pburg(xw,40, Nfft, fs);
  S0 = fft(xw, Nfft);
  
  S0 = abs(S0);
  #S0 = log(S0);
  #S0 = S0/max(S0(:)); 
  #S0 = max(S0, 10^(-40/10)); 
  #S0 = min(S0, 10^(-3/10));

  S = [S, S0];
    
  #[pb, nic] = pburg(xw, 20, Nfft, fs);
  #S = [S, pb];
  
  ## energia
  E = [E, sum(xw.^2, 1)];
  
  ## subband energie
  sub0 = subband_filter(B, A, xx);
  sub0 = abs(sub0);
  #sub0 = sub0 /max(sub0(:)); 
  
  #sub0 = log(sub0);
  #sub0 = max(sub0, 10^(-40/10)); 
  #sub0 = min(sub0, 10^(-3/10));

  sub_energies = [sub_energies, sub0];
  
  #max(sub_energies (:))
  # mf = [mf, MorganFosler(abs(S(:, end)).^2)];   # vsetky riadky, posledny stlpec
  
  if (k >= K-1)
    ds_old = [ds_old, DagenShrikanth( (abs(S(:, (end-K+1):end)).^2) .* wg') ];
    ds_new = [ds_new, DagenShrikanth( (sub_energies(:, (end-K+1):end)) .* wg')];
  end
  
  k++;
  printf('progress: %d %%\r', fix(k / maxK * 100))
end

subplot(5, 1, 2);

# energy = sum(abs(_S).^2 / Nfft, 1);     #nebolo spravne

plot(E, "r")

axis([0, size(S,2)]);

subplot(5, 1, 3);

#colormap(gca, flipud(gray()));
colormap(gca, gray());

spec_limit = 47;
f = [0: spec_limit-1] ./ Nfft .* fs;

imagesc(t, f, 1-S(1:spec_limit, :));
axis([t(1), t(end)]);
#imagesc(t, f, log(S));
set(gca,'YDir','normal');

subplot(5, 1, 4);

#plot(1:length(ds_old), ds_old/max(ds_old), 1:length(ds_new), ds_new/max(ds_new), 1:length(mf), mf/max(mf))
#plot(1:length(ds_old), log(ds_old/max(ds_old)), 1:length(ds_new), log(ds_new/max(ds_new)))

x = ds_new/max(ds_new);
for s = 1:length(x)
    if x(s) > 10^-5
      break
    end
end

for e = length(x):-1:s+1
    if x(e) > 10^-5
      break
    end
end

x = x(s:e);
#min(x)
#xx = x + 25;

plot(log(x));

## hladanie prizvuku
x_len = length(sound_dict.(my_word).stress_seq);
x_part = length(x)/x_len;
[val, idx] = max(x);
chlievik = floor(idx/x_part) + 1;
if sound_dict.(my_word).stress_seq(chlievik) == '1' 
  printf('yes')
else
  printf('no')
end
#axis([0, size(S,2)]);

subplot(5, 1, 5)
colormap(gca, flipud(gray()));
imagesc(t, 1:size(sub_energies, 1), sub_energies);
axis([t(1), t(end)]);
set(gca,'YDir','normal');
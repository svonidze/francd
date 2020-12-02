# __franc__
Natural language detection tool.

## Features
   - Supports 187 languages;
   - no external dependencies;
   - 100% Dart.

## How does it work?
The algorithm is based on the trigram language models, which is a particular case of n-grams. To understand the idea, please check the original whitepaper Cavnar and Trenkle ['94: N-Gram-Based Text Categorization'](https://www.researchgate.net/publication/2375544_N-Gram-Based_Text_Categorization).

## Requirements
Dart 2.0.0 or higher.

## Usage
#### import
```
import 'package:franc/franc.dart';
```
#### make object
```
final franc = Franc();
```
#### detect languages:
```
print(await franc.detectLanguages("Я пришёл к тебе с приветом"));
```
#### yields:
```
{srp: 1.0, bul: 0.9960022844089091, bos: 0.9954311821816105, rus: 0.8772130211307824, mkd: 0.8663620788121074, ukr: 0.8223872073101085, koi: 0.6419189034837236, bel: 0.608223872073101, uzn: 0.5294117647058824, kbd: 0.4848657909765848, kaz: 0.4557395773843518, kir: 0.4351798972015991, azj: 0.3426613363792119}
```

## Derivation
This is a derivative of [Franc](https://github.com/wooorm/franc/) (JavaScript, MIT) by Titus Wormer.

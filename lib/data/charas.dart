import '../models/chara.dart';
import 'theme.dart';

const sun = Chara(
  id: 'sun',
  name: 'たいよう',
  accent: AppColors.sun,
  accentDeep: AppColors.sunDeep,
);

const moon = Chara(
  id: 'moon',
  name: '月',
  accent: AppColors.moon,
  accentDeep: AppColors.moonDeep,
);

const earth = Chara(
  id: 'earth',
  name: '地球',
  accent: AppColors.earth,
  accentDeep: AppColors.earthDeep,
);

const charas = <Chara>[sun, moon, earth];

Chara charaById(String id) => charas.firstWhere((c) => c.id == id);

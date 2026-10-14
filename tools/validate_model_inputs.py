"""Check all released input hashes, numeric shapes, folds and private fields."""
from pathlib import Path
import csv,gzip,hashlib,json,math,re
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'data/model-inputs'
def rows(p):
 with p.open(newline='') as f:return list(csv.DictReader(f))
manifest=rows(BASE/'manifest.csv')
assert len({r['path'] for r in manifest})==len(manifest)
private=re.compile(r'/Users/|/Volumes/|HEX250_|BEGIN .*PRIVATE KEY|github_pat_|ghp_[A-Za-z0-9]{30,}')
coordinate={'latitude','longitude','lat','lon','lng','x_4547','y_4547','site_x','site_y','wkt','geometry','private_site','private_cell'}
def walk(x):
 if isinstance(x,dict):
  assert not (set(map(str.lower,x)) & coordinate)
  if set(x)=={'dim','values'}:assert math.prod(x['dim'])==len(x['values'])
  for v in x.values():walk(v)
 elif isinstance(x,list):
  for v in x:walk(v)
 elif isinstance(x,(int,float)):assert math.isfinite(x)
for r in manifest:
 p=ROOT/r['path'];assert p.is_file()
 assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],r['path']
 assert p.stat().st_size==int(r['bytes'])
 if p.suffix=='.gz':
  text=gzip.open(p,'rt').read();walk(json.loads(text))
 else:
  text=p.read_text()
  if p.suffix=='.csv':assert not(set(next(csv.reader(text.splitlines())))&coordinate)
 assert not private.search(text),p.name
inventory={p.relative_to(ROOT).as_posix() for folder in (BASE,ROOT/'data/model-outputs') for p in folder.rglob('*') if p.is_file() and p.name not in ('README.md','manifest.csv')}
assert inventory=={r['path'] for r in manifest},'Input/output manifest is incomplete'
full=json.loads(gzip.open(BASE/'occupancy/full_H4_M01.json.gz','rt').read())
assert full['y']['dim']==[31,68,7]
values=full['y']['values'];assert sum(v is not None for v in values)==9912
assert sum(v==1 for v in values)==2682 and sum(v is None for v in values)==4844
codes=set(full['station_id']);assert codes=={f'ST{i:02d}' for i in range(1,32)}
folds=rows(BASE/'folds.csv');assert len(folds)==31 and {r['station_id'] for r in folds}==codes
for fold in range(1,6):
 held={r['station_id'] for r in folds if int(r['fold_id'])==fold}
 for role in ('H0_P0','corvid_assemblage','sturnid_assemblage','black_faced_laughingthrush','H4_M01','H4_M02','H4_M03'):
  train=json.loads(gzip.open(BASE/f'occupancy/fold{fold:02d}_{role}_train.json.gz','rt').read())
  test=json.loads(gzip.open(BASE/f'occupancy/fold{fold:02d}_{role}_test.json.gz','rt').read())
  a=set(train['station_id']);b=set(test['station_id']);assert not(a&b) and a|b==codes and b==held
  assert train['y']['dim'][1:]==test['y']['dim'][1:]==[68,7]
assert len(rows(BASE/'daily_counts.csv'))==9912
assert len(rows(BASE/'city_predictors.csv'))==13714
assert len(rows(BASE/'hourly_counts.csv'))==64141
print(f'Model-input checks PASS: {len(manifest)} checksummed files; full shapes, missing masks, fivefold separation and private-field scan.')

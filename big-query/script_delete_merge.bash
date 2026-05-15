bq query --use_legacy_sql=false < del_tmp_vendedores1.sql
sleep 10
bq load --format=csv --skip_leading_rows=0 belleza_verde_vendas.ho.tmp_vendedores1
sleep 10
gs://curso_storage/vendedores.csv tmp_vendedores1.json
bq query --use_legacy_sql=false < merge_vendedores1.sql
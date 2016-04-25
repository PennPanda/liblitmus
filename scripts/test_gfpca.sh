source test_case_list.sh

cd ../

echo "---test_case 1 start---"
CASE=1
WAIT=1
DUR=60
test_case 1
echo "---test_case 1 finish---"

echo "---test_case 6 start---"
CASE=6
WAIT=1
DUR=60
test_case 6
echo "---test_case 6 finish---"

echo "---test_case 8 start---"
CASE=8
WAIT=1
DUR=60
test_case 8
echo "---test_case 8 finish---"

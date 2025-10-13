

            docker build -t jmeter .

            docker run --rm -v $(pwd):/tests -w /tests my-jmeter \
    -n -t basic_test.jmx -l results.jtl -e -o report/ 2>&1 | tee jmeter_output.log

            open report/index.html 
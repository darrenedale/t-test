use std::env;
use std::io::Read;
use std::fs::File;
use std::f64::INFINITY as Infinity;

type DataItem = f64;
type Data = Vec<(DataItem, DataItem)>;

fn output_data(data: &Data) {
    for item in data {
        println!("{}, {}", item.0, item.1);
    }
}

fn output_descriptive_stats(data: &Data) {
    let mut sums: (DataItem, DataItem) = (0.0, 0.0);

    for item in data {
        sums.0 += item.0;
        sums.1 += item.1;
    }

    println!("Sum : {}, {}", sums.0, sums.1);
    println!("Mean: {}, {}", sums.0 / (data.len() as DataItem), sums.1 / (data.len() as DataItem));
}

fn paired_t(data: &Data) -> DataItem {
    let df: i64 = (data.len() - 1) as i64;
    let mut sum_of_differences: DataItem = 0.0;
    let mut sum_of_squared_differences: DataItem = 0.0;

    for item in data {
        let diff = item.1 - item.0;
        sum_of_differences += diff;
        sum_of_squared_differences += diff.powf(2.0);
    }

    let mut t = data.len() as DataItem * sum_of_squared_differences - sum_of_differences.powf(2.0);
    t /= df as DataItem;
    t = t.sqrt();

    if 0.0 == t {
        t = Infinity;
    }
    else {
        t = sum_of_differences / t;
    }

    if 0.0 > t {
        t = -t;
    }

    return t;
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("Missing datafile.");
        return;
    }

    println!("Data file: {}", &args[1]);
    let mut content = String::new();
    File::open(&args[1]).expect("Failed to open file.").read_to_string(&mut content).expect("Failed to read file.");
    let mut data: Data = Data::new();

    for line in content.lines() {
        let mut items = line.split(",");

        data.push(
            (
                items.next().expect("Data item 1 missing.").parse::<f64>().expect("Non-numeric item 1 in data file."),
                items.next().expect("Data item 2 missing.").parse::<f64>().expect("Non-numeric item 2 in data file.")
            )
        );
    }

    let t = paired_t(&data);
    output_data(&data);
    output_descriptive_stats(&data);
    println!("t = {}", t);
}

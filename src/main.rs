extern crate reqwest;

fn main() -> Result<(), Box<dyn std::error::Error>> {
  let body = reqwest::get("https://www.rust-lang.org")?.text()?;

  println!("hi: {}", body);
  Ok(())
}

# 🖼️ mdpics

**Convert all image URLs in a Markdown file to embedded base64 images**

> *“Inspired by a problem I came across on Reddit.”*
> — Author: Amr Alasmer

---

## What is this?

`mdpics` is a Bash script that scans a Markdown (`.md`) file, finds all remote image links (like `![Alt Text](https://example.com/image.jpg)`), downloads those images, encodes them in base64, and replaces the links with embedded image data (like `![Alt Text](data:image/jpeg;base64,...)`).
This makes the resulting Markdown file **self-contained** — all images are embedded directly, no need for external hosting.

---

## Features

* Detects and processes all HTTP(S) image URLs in a `.md` file
* Downloads images in parallel for faster processing
* Detects image MIME types using headers or file signature
* Outputs the final Markdown to `stdout` with images embedded as base64
* Cleans up all temporary files after execution
* Uses standard UNIX tools — no special dependencies

---

## Dependencies

Make sure you have the following installed:

* `bash`
* `curl`
* `base64`
* `gawk`

You can install them with:

```bash
sudo apt install curl coreutils gawk bash
```

---

## Usage

```bash
./mdpics myfile.md > embedded.md
```

* Input: `myfile.md` with image links like `![Example](https://example.com/image.png)`
* Output: Markdown printed to `stdout` with images embedded as base64

---

## Example

Original `input.md`:

```markdown
# My Notes

Here's a picture:

![Cute Cat](https://example.com/cat.png)
```

Run the script:

```bash
./mdpics input.md > output.md
```

The result `output.md` will now contain:

```markdown
# My Notes

Here's a picture:

![Cute Cat](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...)
```



---

## License

This project is licensed under the **GNU General Public License v3 or later**.

---

## Author

**Amr Alasmer**
This tool was developed to solve a real-world problem I saw on reddit and is shared with the hope it will help others too.


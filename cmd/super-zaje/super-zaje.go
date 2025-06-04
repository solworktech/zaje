package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/gen2brain/go-fitz"
	"github.com/jessp01/zaje"
	"github.com/otiai10/gosseract/v2"
	"github.com/urfave/cli"
)

func main() {

	var isPdf bool

	var pdfPage int

	app := cli.NewApp()
	zaje.PopulateAppMetadata(app)

	app.Flags = append(app.Flags, cli.BoolFlag{
		Name:        "remove-line-numbers, rln",
		Usage:       "Remove line numbers.\n",
		Destination: &zaje.RemoveLineNumbers,
	},
	)

	app.Flags = append(app.Flags, cli.BoolFlag{
		Name:        "pdf",
		Usage:       "Pass if input is a PDF file.\n",
		Destination: &isPdf,
	},
	)

	app.Flags = append(app.Flags, cli.IntFlag{
		Name:        "pdf-page-number, pn",
		Usage:       "When working on a PDF, set the page to process (first page is 0, not 1).\n",
		Destination: &pdfPage,
	},
	)

	app.Action = func(c *cli.Context) error {
		log.SetFlags(log.LstdFlags | log.Lshortfile)
		fi, err := os.Stdin.Stat()
		if err != nil {
			panic(err)
		}

		var filename string

		if fi.Mode()&os.ModeNamedPipe == 0 {
			if !zaje.BuildInfo && c.NArg() < 1 {
				return errors.New("no input file provided. " + app.Name + " needs a file or data from STDIN")
			}
			filename = c.Args().Get(0)
			if isPdf {
				imgFileName := filepath.Join(os.TempDir(), fmt.Sprintf("%s_p%d.png", filepath.Base(filename), pdfPage))
				imageFilePtr, err := os.Create(imgFileName)
				if err != nil {
					log.Fatal(err)
				}
				doc, err := fitz.New(filename)
				if err != nil {
					log.Fatal(err)
				}

				img, err := doc.ImagePNG(pdfPage, 300.00)
				if err != nil {
					log.Fatal(err)
				}

				err = os.WriteFile(imgFileName, img, 0644)
				if err != nil {
					log.Fatal(err)
				}

				imageFilePtr.Close()
				doc.Close()
				filename = imgFileName
			}
			data, err := zaje.ReadDataFromFile(filename)
			if err != nil {
				log.Fatal(err)
			}

			mimeType := http.DetectContentType(data)
			if strings.HasPrefix(mimeType, "image") {
				imgDestination := filename
				if _, err := os.Stat(filename); errors.Is(err, os.ErrNotExist) {
					imgDestination = os.TempDir() + "/" + filepath.Base(filename)
					zaje.DownloadFile(filename, imgDestination)
				}
				client := gosseract.NewClient()
				defer client.Close()

				client.Trim = true
				client.SetImage(imgDestination)
				client.SetLanguage("eng")
				err := client.SetVariable("tessedit_char_whitelist", " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")
				if err != nil {
					panic(err)
				}

				text, err := client.Text()
				if err != nil {
					panic(err)
				}
				if zaje.RemoveLineNumbers {
					reLineNumber := regexp.MustCompile(`(?m)^\s*\d+\s(.*)`)
					text = reLineNumber.ReplaceAllString(text, `$1`)
				}
				data = []byte(text)
			}

			zaje.HandleData(filename, data)
		} else {
			// if progressive (i.e `tail -f` or ping)
			if c.Args().Get(0) == "-" {
				scanner := bufio.NewScanner(os.Stdin)

				for scanner.Scan() {
					data := scanner.Text()
					zaje.HandleData(filename, []byte(data))
				}

				if err := scanner.Err(); err != nil {
					log.Fatal(err)
				}
				// read everything and process
			} else {
				data, err := io.ReadAll(os.Stdin)
				if err != nil {
					panic(err)
				}
				zaje.HandleData(filename, []byte(data))
			}
		}
		return nil
	}

	err := app.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}
}

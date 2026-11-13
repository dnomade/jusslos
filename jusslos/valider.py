"""Validerer alle dokumenter og manifest.json mot JSON-skjemaene."""
import json, pathlib, sys
from jsonschema import Draft202012Validator

ROT = pathlib.Path(__file__).resolve().parent.parent


def main() -> int:
    data = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROT
    dok = Draft202012Validator(json.loads((ROT / "schema/dokument.schema.json").read_text("utf-8")))
    man = Draft202012Validator(json.loads((ROT / "schema/manifest.schema.json").read_text("utf-8")))
    feil = 0
    for f in sorted((data / "data").rglob("*.json")):
        for e in dok.iter_errors(json.loads(f.read_text("utf-8"))):
            feil += 1
            if feil <= 20:
                print(f"{f.relative_to(data)}: {e.json_path}: {e.message[:200]}")
    m = data / "manifest.json"
    if m.exists():
        for e in man.iter_errors(json.loads(m.read_text("utf-8"))):
            feil += 1
            print(f"manifest.json: {e.json_path}: {e.message}")
    print(f"{feil} valideringsfeil.")
    return 1 if feil else 0


if __name__ == "__main__":
    sys.exit(main())
